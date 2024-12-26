from pynput import keyboard

def on_press(key):
    try:
        print(f"Key pressed: {key.char}")
    except AttributeError:
        print(f"Special key pressed: {key}")

def on_release(key):
    try:
        print(f"Key released: {key.char}")
    except AttributeError:
        print(f"Special key released: {key}")

    # 停止监听
    if key == keyboard.Key.esc:
        return False

def on_press(key):
    try:
        print(f"Key pressed: {key.char}")
    except AttributeError:
        print(f"Special key pressed: {key}")

def on_release(key):
    try:
        if hasattr(key, 'char') and key.char is not None:
            print(f"Key released: {key.char}")
        else:
            print(f"Special key released: {key}")
    except AttributeError:
        print(f"Special key released: {key}")

    # 停止监听
    if key == keyboard.Key.esc:
        return False

# 创建监听器
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
    