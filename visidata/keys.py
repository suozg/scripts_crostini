# налаштування клавіш VisiData
#-------------------------------------------
from visidata import TableSheet, BaseSheet

# 1. Спочатку видаляємо базові/стандартні прив'язки для цих символів
TableSheet.unbindkey('.')
BaseSheet.unbindkey('.')

# 2. Прив'язуємо крапку до пошуку (search-col)
TableSheet.bindkey('.', 'search-col')
BaseSheet.bindkey('.', 'search-col')

# 3. Навігація та пошук
TableSheet.bindkey('о', 'cursor-down')
TableSheet.bindkey('л', 'cursor-up')
TableSheet.bindkey('у', 'edit-cell')

BaseSheet.bindkey('т', 'search-next')
BaseSheet.bindkey('Т', 'search-prev')
BaseSheet.bindkey('й', 'quit-sheet')

# 4. Копіювання (українська розкладка для y / Y)
TableSheet.bindkey('н', 'syscopy-row')
TableSheet.bindkey('Н', 'syscopy-cell')
BaseSheet.bindkey('н', 'syscopy-row')
BaseSheet.bindkey('Н', 'syscopy-cell')

