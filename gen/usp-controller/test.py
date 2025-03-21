#!/usr/bin/env python3

import subprocess
import re
import json
import time


from google.protobuf.json_format import MessageToJson



def call_mqtt_script(broker_ip, port, topic, command):
    # Prepare the command to execute the mqtt-usp-client.py script
    script_command = ['./mqtt-usp-client.py', broker_ip, str(port), topic, command]

    # Execute the script and capture the output
    result = subprocess.run(script_command, capture_output=True, text=True)
    
    # Check if there was an error
    if result.returncode != 0:
        print("Error executing script:", result.stderr)
        return None

    return result.stdout


def UspPa(arg1, arg2):

    broker_ip = "10.10.10.107"
    port = 1883
    topic = "/usp/controller"

    # Call the MQTT script and get output
    output = call_mqtt_script(broker_ip, port, topic, arg1 + ' ' + arg2)

    return(output)


'''

https://usp.technology/specification/#sec:software-module-management


UspPa get Device.DeviceInfo.SerialNumber

UspPa get Device.SoftwareModules.
UspPa get Device.SoftwareModules.ExecEnv.

i686:
UspPa operate "Device.SoftwareModules.InstallDU(ExecutionEnvRef=test,UUID=sleepy,URL=https://raw.githubusercontent.com/robvogelaar/robvogelaar.github.io/main/unlisted/dac-images/dac-image-webui-v3.1-i686.tar.gz)"

arm:
UspPa operate "Device.SoftwareModules.InstallDU(ExecutionEnvRef=test,UUID=sleepy,URL=https://raw.githubusercontent.com/robvogelaar/robvogelaar.github.io/main/unlisted/dac-images/dac-image-webui-v3.1-i686.tar.gz)"

UspPa get Device.SoftwareModules.DeploymentUnit.
UspPa get Device.SoftwareModules.ExecutionUnit.

UspPa operate "Device.SoftwareModules.ExecutionUnit.1.SetRequestedState(RequestedState=Active)"
UspPa operate "Device.SoftwareModules.ExecutionUnit.1.SetRequestedState(RequestedState=Idle)"
UspPa get Device.SoftwareModules.DeploymentUnit.
UspPa operate "Device.SoftwareModules.DeploymentUnit.1.Uninstall()"
UspPa get Device.SoftwareModules.DeploymentUnit.



./mqtt-usp-client.py 10.10.10.107 1883 /usp/controller "get Device.SoftwareModules.ExecEnv."
./mqtt-usp-client.py 10.10.10.107 1883 /usp/controller "operate Device.SoftwareModules.InstallDU(ExecutionEnvRef=test,UUID=sleepy,URL=https://raw.githubusercontent.com/robvogelaar/robvogelaar.github.io/main/unlisted/dac-images/dac-image-webui-v3.1-i686.tar.gz)"

'''


def main():

    ret = UspPa("get", "Device.DeviceInfo.SerialNumber")
    print(ret)

    # Assuming in_usp_msg is a Protobuf object that's been populated
    json_data = json.loads(ret)

    #print(json_data)
    #exit()

    serial_number = json_data["reqPathResults"][0]["resolvedPathResults"][0]["resultParams"]["SerialNumber"]

    if serial_number:
        print("Serial Number:", serial_number)
    else:
        print("Serial Number not found.")

    exit()


    ret = UspPa("get", "Device.SoftwareModules.ExecEnv.1.")
    print(ret)


    ret = UspPa("get", "Device.SoftwareModules.DeploymentUnit.")
    print(ret)

    ret = UspPa("operate", "Device.SoftwareModules.InstallDU(ExecutionEnvRef=test,UUID=sleepy,URL=https://raw.githubusercontent.com/robvogelaar/robvogelaar.github.io/main/unlisted/dac-images/dac-image-webui-v3.1-i686.tar.gz)")
    print(ret)

    time.sleep(5)

    ret = UspPa("get", "Device.SoftwareModules.DeploymentUnit.")
    print(ret)


    ret = UspPa("operate", "Device.SoftwareModules.DeploymentUnit.1.Uninstall()")
    print(ret)


if __name__ == '__main__':
    main()
