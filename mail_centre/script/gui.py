import sys  
import csv  
import re
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLineEdit, QTextEdit, QPushButton,QMessageBox  
from PyQt5.QtCore import QDateTime  
  
class MessageApp(QWidget):  
    def __init__(self):  
        super().__init__()  
        self.initUI()  
  
    def initUI(self):  
        self.setWindowTitle('Message Sender')  
        self.setGeometry(100, 100, 800, 600)  
  
        layout = QVBoxLayout()  

        # Create input box for email address  
        self.email_input = QLineEdit(self)  
        self.email_input.setPlaceholderText('Input email address')  
        layout.addWidget(self.email_input)
  
        self.textArea = QTextEdit(self)  
        layout.addWidget(self.textArea)  
  
        self.sendButton = QPushButton('Send Message', self)  
        self.sendButton.clicked.connect(self.writeToCSV)  
        layout.addWidget(self.sendButton)  
  
        self.setLayout(layout)  
  
    def writeToCSV(self):  
        tasks = []
        
        current_time = QDateTime.currentDateTimeUtc().toString("yyyy-MM-dd hh:mm:ss.zzz000+00:00")  
        sender = self.email_input.text() 
        if '@amd.com' not in sender:  
            QMessageBox.warning(self, 'Invalid Email', 'Email address must contain @amd.com')  
            return
        mail_body = self.textArea.toPlainText()  
        print(mail_body)
        # Define other fields as empty or default values  
        tag = ""  
        subject = ""  
        mail_quote = ""  
        reply = ""  
        instruction = ""  
        run_dir = ""  
        status = ""  
        current_time = re.sub('Z','',current_time)
        tag = re.sub('000\+00:00','',str(current_time))
        tag = re.sub('[ :-]','',tag)
        tag = re.sub('^20','',tag)
        tag = re.sub('\.','',tag)
        tag = re.sub('\+.*','',tag)
        tag_cut = tag[0:15]
        task = {'time' : current_time, 'tag':tag_cut,'sender':sender,'subject' : '', 'mailBody' : mail_body,\
                                'mailQuote' : '',\
                                'reply': '','instruction':'','runDir' : '','status' : ''}
        tasks.append(task)
        # Write to CSV  
        with open("chatbot.csv", mode="w", encoding="utf-8-sig", newline="") as f:
            header_list = ["time", "tag","sender","subject", "mailBody","mailQuote","reply","instruction","runDir","status"]
            writer = csv.DictWriter(f,header_list)
            writer.writeheader() 
            writer.writerows(tasks)
            f.close() 
  
        # Clear the text area after sending  
        self.textArea.clear()  
  
if __name__ == '__main__':  
    app = QApplication(sys.argv)  
    ex = MessageApp()  
    ex.show()  
    sys.exit(app.exec_())  
