import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, OneHotEncoder

def clean_data(path: str):
    df = pd.read_csv(path)
    df['b_day'] = pd.to_datetime(df['b_day'], format='%m/%d/%y', errors='coerce')
    df['draft_year'] = pd.to_datetime(df['draft_year'], format='%Y', errors='coerce')
    df['team'] = df['team'].fillna('No Team')
    df['height'] = df['height'].str.extract(r'([\d.]+)$').astype(float)
    df['weight'] = df['weight'].str.extract(r'([\d.]+)\s*kg').astype(float)
    df['salary'] = df['salary'].str.replace('$', '').astype(float)
    df['country'] = df['country'].apply(lambda x: 'USA' if x == 'USA' else 'Not-USA')
    df['draft_round'] = df['draft_round'].replace('Undrafted', '0')
    return df

def feature_data(dataframe: pd.DataFrame):
    dataframe['version'] = pd.to_datetime(dataframe['version'], format='NBA2k%y')
    dataframe['age'] = dataframe['version'].dt.year - dataframe['b_day'].dt.year
    dataframe['experience'] = dataframe['version'].dt.year - dataframe['draft_year'].dt.year
    dataframe['bmi'] = dataframe['weight'] / (dataframe['height'] ** 2)
    dataframe.drop(['version', 'b_day', 'draft_year', 'weight', 'height'], axis=1, inplace=True)
    to_drop = {col for col in dataframe.columns if dataframe[col].nunique() > 50 and dataframe[col].dtype == object}
    dataframe.drop(to_drop, axis=1, inplace=True, errors='ignore')
    return dataframe

def multicol_data(dataframe: pd.DataFrame):
    corr_matrix = dataframe.drop(columns='salary').corr(numeric_only=True).abs()
    collinear_features = corr_matrix[(corr_matrix < 1) & (corr_matrix > 0.5)].dropna(how='all').index
    features_to_drop = dataframe[collinear_features].corrwith(dataframe['salary']).idxmin()
    return dataframe.drop(columns=features_to_drop)

def transform_data(df):
    num_df = df.select_dtypes('number').drop(columns='salary')
    scaler = StandardScaler()
    num_scaled = pd.DataFrame(scaler.fit_transform(num_df), columns=num_df.columns)
    cat_df = df.select_dtypes('object')
    onehot = OneHotEncoder(sparse_output=False)
    cat_encoded = pd.DataFrame(onehot.fit_transform(cat_df), columns=np.concatenate(onehot.categories_))
    return pd.concat([num_scaled, cat_encoded], axis=1), df['salary']
