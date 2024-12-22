from flask import Flask, jsonify, request
import keyboard
import argparse
import socket
import qrcode

app = Flask(__name__)

@app.route('/heartbeat', methods=['GET'])
def heartbeat():
    return jsonify(status='alive')

@app.route('/keyboard', methods=['POST'])
def keyboard_event():
    try:
        data = request.get_json()
        print(data)
        keyboard.press_and_release(data['key'])
        return jsonify(status='ok')
    except Exception as e:
        return jsonify(status='error', message=str(e))
def get_all_ip_addresses():
    hostname = socket.gethostname()
    ip_addresses = socket.gethostbyname_ex(hostname)[2]
    return ip_addresses
def generate_qr_code(data):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)
    qr.print_ascii()
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='将收到的post请求转发到本地键盘')
    parser.add_argument('-p', '--port', type=int, default=24122, help='服务器端口, 默认24122，例:-p 14514')
    args = parser.parse_args()
    ips = get_all_ip_addresses()
    ip_str = str(args.port)+"\n"+"\n".join(ips)
    generate_qr_code(ip_str)
    app.run(host='0.0.0.0', port=args.port, debug=True)