import os
import threading
import tkinter as tk
from tkinter import messagebox
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


auto_save_timer = None
inactivity_timer = None
root = tk.Tk()
root.withdraw()  
fields = ['Type Order', 'lotSize', 'StopLoss', 'TakeProfit']
entries = {}


class MyHandler(FileSystemEventHandler):
    def __init__(self, callback):
        self.callback = callback

    def on_modified(self, event):
        if event.src_path.endswith("EOrderGraph.txt"):
            self.callback()

def check_file_and_load_data():
    global auto_save_timer
    try:
        with open("EOrderGraph.txt", "r") as file:
            content = file.read().strip()
            if not content:
                root.withdraw()  
                return
            if content.endswith(";"):
                content = content[:-1]
            data = content.split(",")
            if len(data) != len(fields):
                root.withdraw() 
                return
            for field, value in zip(fields, data):
                if field == 'Type Order':
                    entries[field].config(state=tk.NORMAL)
                entries[field].delete(0, tk.END)
               
                if field == 'Type Order':
                    if value == "OP_BUY":
                        value = "OP_SELL"
                    elif value == "OP_SELL":
                        value = "OP_BUY"
                entries[field].insert(0, value)
                if field == 'Type Order':
                    entries[field].config(state='readonly')
            root.deiconify() 
            reset_inactivity_timer()
    except FileNotFoundError:
        root.withdraw()  

def reset_inactivity_timer():
    global inactivity_timer
    if inactivity_timer is not None:
        inactivity_timer.cancel()
    inactivity_timer = threading.Timer(15, save_data)
    inactivity_timer.start()

def save_data():
    global auto_save_timer, inactivity_timer
    if auto_save_timer is not None:
        auto_save_timer.cancel()
    if inactivity_timer is not None:
        inactivity_timer.cancel()
    data = [entries[field].get() for field in fields]
    with open("IOrderGraph.txt", "w") as file:
        file.write(",".join(data))
    with open("EOrderGraph.txt", "w") as file:
        file.write("")
    root.withdraw()

def create_gui():
    for field in fields:
        row = tk.Frame(root)
        label = tk.Label(row, width=15, text=field, anchor='w')
        entry = tk.Entry(row)
        entry.bind("<Key>", lambda event: reset_inactivity_timer()) 
        if field == 'Type Order':
            entry.config(state='readonly')
        row.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        label.pack(side=tk.LEFT)
        entry.pack(side=tk.RIGHT, expand=tk.YES, fill=tk.X)
        entries[field] = entry
    tk.Button(root, text='Guardar Cambios', command=save_data).pack(side=tk.TOP, padx=5, pady=5)

def start_monitoring():
    path = os.path.dirname(os.path.abspath(__file__))
    event_handler = MyHandler(check_file_and_load_data)
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    observer.start()
    try:
        root.mainloop()
    finally:
        observer.stop()
        observer.join()

if __name__ == "__main__":
    create_gui()
    check_file_and_load_data()  
    start_monitoring()