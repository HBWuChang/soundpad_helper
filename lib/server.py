from flask import Flask, jsonify, request, send_from_directory
from pynput.keyboard import Key, Controller, KeyCode
import argparse
import socket
import os
# import qrcode
import time
import json

keyboard = Controller()

app = Flask(__name__)


@app.route("/heartbeat", methods=["GET"])
def heartbeat():
    return jsonify(status="alive")


@app.route("/keyboard", methods=["POST"])
def keyboard_event():
    try:
        data = request.get_json()
        print(data)
        # time.sleep(1)
        keyboard.press(Key.alt_l)
        time.sleep(0.02)
        for key in data["key"]:
            t = int(key) + 96
            keyboard.press(KeyCode.from_vk(t))
            time.sleep(0.02)
        for key in data["key"]:
            t = int(key) + 96
            time.sleep(0.02)
            keyboard.release(KeyCode.from_vk(t))
        keyboard.release(Key.alt_l)
        return jsonify(status="ok")
    except Exception as e:
        return jsonify(status="error", message=str(e))


@app.route("/stop", methods=["POST"])
def stop():
    try:
        keyboard.press(Key.alt_l)
        keyboard.press("0")
        time.sleep(0.05)
        keyboard.release("0")
        keyboard.release(Key.alt_l)
        return jsonify(status="ok")
    except Exception as e:
        return jsonify(status="error", message=str(e))


@app.route("/", methods=["GET"])
def index():
    print("index")
    return send_from_directory("web", "index.html")


@app.route("/<path:filename>", methods=["GET"])
def serve_file(filename):
    return send_from_directory("web", filename)


def get_all_ip_addresses():
    hostname = socket.gethostname()
    ip_addresses = socket.gethostbyname_ex(hostname)[2]
    return ip_addresses

@app.route("/save_config", methods=["POST"])
def save_config():
    try:
        data = request.get_data().decode("utf-8")
        with open(os.path.join(rootdir, "config.json"), "w", encoding="utf-8") as f:
            f.write(data)
        return jsonify(status="ok")
    except Exception as e:
        return jsonify(status="error", message=str(e))

@app.route("/load_config", methods=["GET"])
def load_config():
    try:
        with open(os.path.join(rootdir, "config.json"), "r", encoding="utf-8") as f:
            data = f.read()
        return jsonify(status="ok", data=data)
    except Exception as e:
        return jsonify(status="error", message=str(e))
        
                       

rootdir = os.path.abspath(os.path.dirname(__file__))
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="将收到的post请求转发到本地键盘")
    parser.add_argument(
        "-p",
        "--port",
        type=int,
        default=24122,
        help="服务器端口, 默认24122，例:-p 14514",
    )
    args = parser.parse_args()
    ips = get_all_ip_addresses()
    print("请尝试以下地址")
    for ip in ips:
        print(ip + ":" + str(args.port))
    # generate_qr_code(ip_str)
    app.run(host="0.0.0.0", port=args.port, debug=True)
