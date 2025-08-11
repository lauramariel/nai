import json

# Assuming 'data.json' contains: {"name": "Alice", "age": 30, "city": "New York"}
try:
    with open('/Users/laura/Downloads/stable-diffusion-output.json', 'r') as file:
        data = json.load(file)
    #print(data)
    print(f"Name: {data[0]['b64_json']}")
except FileNotFoundError:
    print("Error: 'stable-diffusion-output.json' not found.")
except json.JSONDecodeError:
    print("Error: Invalid JSON format in 'stable-diffusion-output.json'.")