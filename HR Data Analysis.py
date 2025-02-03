import pandas as pd

def reindexing(a, b):
    frame = pd.read_xml(a).set_index("employee_office_id")
    frame.index = [f"{b}{i}" for i in frame.index]
    return frame

def count_bigger_5(a):
    return (a > 5).sum()

frame_hr = pd.read_xml("hr_data.xml").set_index("employee_id")
frame_A = reindexing("A_office_data.xml", "A")
frame_B = reindexing("B_office_data.xml", "B")

both = pd.concat([frame_A, frame_B])
both = both.merge(frame_hr, left_index=True, right_index=True, indicator="new_column")
both.drop(columns=["new_column"], inplace=True)
both.sort_index(inplace=True)

first = both.pivot_table(index="Department", 
                         columns=["left", "salary"], 
                         values="average_monthly_hours", 
                         aggfunc="median")
second = both.pivot_table(index="time_spend_company", 
                          columns="promotion_last_5years", 
                          values=["satisfaction_level", "last_evaluation"], 
                          aggfunc=['max', 'mean', 'min'])

q1 = first.query("(`(0, 'high')` < `(0, 'medium')`) or (`(1, 'low')` < `(1, 'high')`)").round(2)
q2 = second.query("`('mean', 'last_evaluation', 0)` > `('mean', 'last_evaluation', 1)`").round(2)

print(q1.to_dict())
print(q2.to_dict())