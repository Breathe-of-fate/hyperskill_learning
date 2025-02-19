import pandas as pd
import matplotlib.pyplot as plt

pd.set_option('display.max_columns', 8)

def handle_frame(name):
    frame = pd.read_csv(name)
    frame.rename(columns={'HOSPITAL': 'hospital', 'Hospital': 'hospital', 'Sex': 'gender', 'Male/female': 'gender'}, inplace=True)
    return frame

all_data = pd.concat([handle_frame("general.csv"), handle_frame("prenatal.csv"), handle_frame("sports.csv")], ignore_index=True)
all_data.drop(columns="Unnamed: 0", inplace=True)

all_data.dropna(how="all", inplace=True)
all_data["gender"] = all_data["gender"].replace({"man":"m", "male": "m", "female":"f", "woman":"f"}).fillna("f")
all_data.fillna(0, inplace=True)

all_data.plot(y='age', kind='hist', bins=[0, 15, 35, 55, 70, 80])
plt.show()
q1 = pd.cut(all_data["age"], bins=[0, 15, 35, 55, 70, 80]).value_counts().idxmax()

all_data.diagnosis.value_counts().plot(kind='pie')
plt.show()
q2 = all_data.diagnosis.value_counts().idxmax()

all_data['height'].value_counts().plot(kind='box')
plt.show()
q3 = "Difference in heigt in m and cm. Two peaks are because of types of patience"

print(f"""The answer to the 1st question: {q1.left}-{q1.right}
The answer to the 2nd question: {q2}
The answer to the 3rd question: {q3}""")