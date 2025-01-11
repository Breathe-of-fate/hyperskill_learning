import pandas

start_data = pandas.read_json('nobel_laureates.json')
print(bool(start_data.duplicated().sum()))
start_data.dropna(subset="gender", inplace=True)
start_data.reset_index(drop=True, inplace=True)
print(start_data[["country", "name"]].head(n=20).to_dict())
