import sys
import subprocess
from PyQt5.QtWidgets import QApplication, QMainWindow, QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget
from PyQt5.QtCore import Qt

class RunDirViewer(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("runDir Navigator")
        self.setGeometry(100, 100, 1920, 800)

        self.table_widget = QTableWidget()
        self.setCentralWidget(self.table_widget)

        self.load_data()
        self.setup_table()

    def load_data(self):
        self.data = []
        with open('runDir.spec', 'r') as file:
            for line in file:
                parts = line.strip().split(',')
                if len(parts) == 4:
                    self.data.append(parts)

    def setup_table(self):
        self.table_widget.setRowCount(len(self.data))
        self.table_widget.setColumnCount(4)
        self.table_widget.setHorizontalHeaderLabels(['Tile Name', 'Target', 'Description', 'Run Dir'])

        for row_idx, row_data in enumerate(self.data):
            for col_idx, item in enumerate(row_data):
                table_item = QTableWidgetItem(item)
                self.table_widget.setItem(row_idx, col_idx, table_item)

        self.table_widget.resizeColumnsToContents()
        self.table_widget.setSortingEnabled(True)
        self.table_widget.cellDoubleClicked.connect(self.open_terminal)

    def open_terminal(self, row, column):
        run_dir = self.table_widget.item(row, 3).text()
        subprocess.Popen(['xterm', '-e', f'csh -c "cd {run_dir} && exec csh"'])

if __name__ == '__main__':
    app = QApplication(sys.argv)
    viewer = RunDirViewer()
    viewer.show()
    sys.exit(app.exec_())
