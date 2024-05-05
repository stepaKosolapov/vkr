import pandas as pd
import matplotlib.pyplot as plt

# Читаем данные из csv файла.
df = pd.read_csv('./results/params.csv')

parameters = df.columns.tolist()[2:]  # Пропускаем 'protocol' и 'nodes'

# Получаем уникальные значения протоколов, чтобы различать их на графиках.
protocols = df['protocol'].unique()

# Определяем стили маркеров и линий для каждого протокола.
# Можно добавить или изменить стили в зависимости от количества протоколов.
markers = ['o', 's', '^']
lines = ['-', '--', '-.']
# Словарь для сопоставления протокола со стилем маркера и линии.
protocol_styles = {protocol: {'marker': markers[i], 'line': lines[i]} for i, protocol in enumerate(protocols)}

# Для каждого параметра создаем отдельный график.
for param in parameters:
    plt.figure(figsize=(10, 6))  # Размер изображения графика
    for protocol in protocols:
        # Фильтруем данные по текущему протоколу.
        protocol_df = df[df['protocol'] == protocol]
        protocol_df = protocol_df.sort_values(by='nodes')

        style = protocol_styles[protocol]
        plt.plot(protocol_df['nodes'], protocol_df[param], marker=style['marker'], linestyle=style['line'], label=protocol)

    # Настраиваем график
    plt.title(f'{param.upper()} vs количество узлов')  # Заголовок
    plt.xlabel('Количество узлов')  # Подпись оси X
    plt.ylabel(param.upper())  # Подпись оси Y
    plt.legend()  # Легенда
    plt.grid(True)  # Сетка
    # Сохраняем график в файл PNG.
    plt.savefig(f'plots/{param}.png') 