import os
import json
import pandas as pd

# Chemin avec espaces échappés
folder_path = "/Users/sarahdinari/desktop/data_lake/reference_tables/secteurs_statistiques"

# Version alternative avec raw string si la première ne fonctionne pas
# folder_path = r"/Users/sarahdinari/desktop/data_lake/reference_tables/Secteurs statistiques"

results = []

try:
    for file in os.listdir(folder_path):
        if file.endswith('.geojson'):
            file_path = os.path.join(folder_path, file)
            try:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    results.append({
                        'filename': file,
                        'type': data['type'],
                        'features_count': len(data['features']),
                        'properties': list(data['features'][0]['properties'].keys()) if data['features'] else []
                    })
            except Exception as e:
                print(f"Erreur avec le fichier {file}: {str(e)}")

    df = pd.DataFrame(results)
    output_path = os.path.join(os.path.dirname(folder_path), 'geojson_analysis.csv')
    df.to_csv(output_path, index=False)
    print(df)

except Exception as e:
    print(f"Erreur générale: {str(e)}")