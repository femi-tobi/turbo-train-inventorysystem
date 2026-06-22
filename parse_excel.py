import zipfile
import xml.etree.ElementTree as ET

path = r'C:\Users\TOBI\inventory_system\assets\Product Master Data.xlsx'
ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

with open(path, 'rb') as f:
    z = zipfile.ZipFile(f)
    print("Files in xlsx:", z.namelist())
    
    # Shared strings
    strings = []
    if 'xl/sharedStrings.xml' in z.namelist():
        ss = ET.fromstring(z.read('xl/sharedStrings.xml'))
        strings = [t.text or '' for t in ss.findall('.//ns:t', ns)]
    
    # Sheet 1
    sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = sheet.findall('.//ns:row', ns)
    print(f"Total rows: {len(rows)}")
    
    for row in rows[:10]:
        cells = []
        for c in row.findall('ns:c', ns):
            v = c.find('ns:v', ns)
            t = c.attrib.get('t', '')
            if v is not None:
                if t == 's':
                    val = strings[int(v.text)]
                else:
                    val = v.text
            else:
                val = ''
            cells.append(val)
        print(cells)
