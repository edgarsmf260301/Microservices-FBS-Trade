import tkinter as tk
from tkinter import messagebox, Entry
import time
import os

def read_last_order():
    try:
        with open('Orders.txt', 'r') as file:
            last_line = None
            for last_line in file:
                pass
            return last_line.strip() if last_line else None
    except Exception as e:
        messagebox.showerror("Error", f"Error al leer Orders.txt: {e}")
        return None

def modify_order_type(order_details):
    if order_details[5] == 'Buy Limit':
        order_details[5] = 'Sell Limit'
    elif order_details[5] == 'Sell Limit':
        order_details[5] = 'Buy Limit'
    return order_details

def ask_duplicate():
    return messagebox.askyesno("Duplicar Orden", "¿Desea duplicar la orden?")

def create_entry_field(root, label, value, row):
    tk.Label(root, text=label).grid(row=row, column=0)
    var = tk.StringVar(root, value=value)
    entry = Entry(root, textvariable=var)
    entry.grid(row=row, column=1)
    return var

def show_modify_window(order_details):
    root = tk.Tk()
    root.title("Modificar Orden")
    entries = {}
    field_names = ['Symbol', 'Volumen', 'StopLoss', 'TakeProfit', 'Commit', 'Type', 'Price', 'OrderTime', 'OrderExpiration']
    
    for index, field in enumerate(field_names):
        if field in ['Symbol', 'Type']:
            tk.Label(root, text=f"{field}: {order_details[index]}").grid(row=index, column=0)
        else:
            entries[field] = create_entry_field(root, field, order_details[index], index)

    def save_order():
        try:
            with open('DuplicateOrders.txt', 'a') as file:
                modified_order = [
                    entries[field].get() if field in entries else order_details[index] for index, field in enumerate(field_names)]
                
                file.write(','.join(modified_order) + ';')
            root.destroy()
        except Exception as e:
            messagebox.showerror("Error", f"Error al guardar la orden duplicada: {e}")

    tk.Button(root, text="Guardar", command=save_order).grid(row=len(field_names) + 1)
    root.mainloop()

def main():
    last_modified_time = None

    while True:
        try:
            if os.path.exists('Orders.txt'):
                current_modified_time = os.path.getmtime('Orders.txt')
                if current_modified_time != last_modified_time:
                    last_order = read_last_order()
                    if last_order:
                        order_details = last_order.split(';')
                        order_details = modify_order_type(order_details)
                        if ask_duplicate():
                            show_modify_window(order_details)
                    last_modified_time = current_modified_time
            time.sleep(1)
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    main()