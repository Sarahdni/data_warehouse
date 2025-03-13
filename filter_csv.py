import os
import json
from collections import defaultdict

folder_path = "/Users/sarahdinari/desktop/data_lake/reference_tables/secteurs_statistiques"

# Dictionnaire pour stocker les propriétés par fichier
properties_by_file = {}
all_properties = set()

# Lire chaque fichier
for file in os.listdir(folder_path):
    if file.endswith('.geojson'):
        with open(os.path.join(folder_path, file), 'r') as f:
            data = json.load(f)
            if data['features']:
                props = set(data['features'][0]['properties'].keys())
                properties_by_file[file] = props
                all_properties.update(props)

# Créer une matrice de comparaison
comparison = defaultdict(dict)
for prop in sorted(all_properties):
    for file in properties_by_file:
        comparison[prop][file] = '✓' if prop in properties_by_file[file] else '✗'

# Sauvegarder en CSV
import pandas as pd
df = pd.DataFrame(comparison).T
df.to_csv(os.path.join(folder_path, 'property_comparison.csv'))
print(df)