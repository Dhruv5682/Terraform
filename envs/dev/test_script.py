import urllib.request
import json

url = "https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/portal_dashboard.html.markdown"
try:
    req = urllib.request.urlopen(url)
    content = req.read().decode('utf-8')
    print("Found docs")
except:
    print("Failed to download")
