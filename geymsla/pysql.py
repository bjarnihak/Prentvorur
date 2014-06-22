import sqlite3

conn = sqlite3.connect("/usr/local/shinken/var/livelogs.db")
cursor = conn.cursor()

print "\nHere's a listing of all the records in the table:\n"
cursor.execute("select *  from logs")

print cursor.fetchall() 
