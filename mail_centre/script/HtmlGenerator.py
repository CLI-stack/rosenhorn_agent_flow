from dominate.tags import *
class HtmlGenerator:
    def __init__(self): 
        self.style_applied = '''
                body{
                    font-family: verdana,arial,sans-serif;
                    font-size:11px;
                }
                table.gridtable {
                    color: #333333;
                    border-width: 1px;
                    border-color: #666666;
                    border-collapse: collapse;
                    font-size:11px;
                }
                table.gridtable th {
                    border-width: 1px;
                    padding: 8px;
                    border-style: solid;
                    border-color: #666666;
                    background-color: #DDEBF7;
                }
                table.gridtable td {
                    border-width: 1px;
                    padding: 8px;
                    border-style: solid;
                    border-color: #666666;
                    background-color: #ffffff;
                    text-align:center;
                }
                table.gridtable td.failed {
                    color:#ED5F5F;
                }
                table.gridtable td.passrate {
                    font-weight:bold;
                    color:green;
                }
                li {
                    margin-top:5px;
                }
                div{
                    margin-top:10px;
                }
            '''
        self.head_list = []
        self.table_list = []
        self.thd = 0
        self.hello = ""
        self.text_list = []
        
    def set_spec(self,hello,text_list,head_list,table_list,thd):
        self.head_list = head_list
        self.table_list = table_list
        self.thd = thd
        self.hello = hello
        self.text_list = text_list
    
    def set_Hello(self,hello):
        hello_str = body
        hello_div = div(id='hello')
        hello_div.add(p('Dear Sir,'))
        hello_div.add(p(hello))

    def set_table_head(self,head_list):
        #head_list = ["Passed","Failed","Total","Pass","Rate,Details"]
        with tr():
            th(style='background-color:white')
            for head in head_list:
                th(head)

    def create_table(self,table_list,thd):
        result_div = div(id='test case result')    
        with result_div.add(table(cls='gridtable')).add(tbody()):
            self.set_table_head(self.head_list)
            for line in table_list:
                data_tr = tr()
                for cell in line:
                    if isinstance(cell,str):
                        data_tr += td(cell)
                    else:
                        cell = round(float(cell),2)
                        if cell>thd:
                            data_tr += td(cell,cls='passrate')
                        else:
                            data_tr += td(cell,cls='failed')
            
    def generate_build_cause(self,cause):
        # skip line
        br()
        div(b(font('Build Information' ,color='#0B610B')))
        div(hr(size=2, alignment='center', width='100%'))
        div((b(font('Cause: Started by upstream pipeline job ' + cause))))
    
    def create_line(self):
        div(hr(size=2, alignment='center', width='100%'))
    
    def create_title(self,title,color):
        div(b(font(title ,color='#0B610B')))
    
    def create_bold_text(self,text):
        div((b(font(text))))
    
    def create_text(self,text):
        p(text)
        
    def create_list(self,text_list):
        list_dot = ul()
        for text in text_list:
            list_dot += li(text)
        
        
    def generate_list_link(self,category, href_link):
        with li(category + ':'):
            a(href_link, href=href_link)

    def generate_build_info(self,build_type, build_url):
        build_type_div = div()
        #build_type_fond = b()
        #build_type_fond += font(build_type + ' Test Build')
        #build_type_div += build_type_fond
        with ul():
            self.generate_list_link('Build', build_url)

    def generate_ending(self):
        br()
        p('** This is an automatically generated email by jenkins job. **')
        p('Feel free to connect xxx-QA@xxx.com if you have any question.')

    def insert_image(self):
        img(src='test_result_trend.png')

    def generate_html_report(self):
        html_root = html()
        # html head
        with html_root.add(head()):
             style(self.style_applied, type='text/css')
        # html body
        with html_root.add(body()):
            self.set_Hello(self.hello)
            self.create_table(self.table_list,self.thd)
            #self.generate_build_cause('Project-XXX/Dev/API')
            self.create_title('Text Tiltle','#0B610B')
            self.create_line()
            self.create_bold_text('Project-XXX/Dev/API')
            self.create_list(self.text_list)
            self.insert_image()
            self.generate_ending()
        # save as html file
        with open('email_report.html', 'w') as f:
            f.write(html_root.render())    

if __name__ == "__main__":
    hg=HtmlGenerator()
    head_list = ["Passed","Failed","Total","Pass","Rate,Details"]
    table_list = []
    text_list = []
    text_list.append("This is the list demo")
    text_list.append("This is the list demo")
    table_list.append(['Smoke Test Suite', 90, 10, '90%', 'Cucumber Report', 'cucumber-html-reports/overview-features.html'])
    table_list.append(['Regression Test Suite', 900, 100, '90%', 'Cucumber Report','cucumber-html-reports/overview-features.html'])
    table_list.append(['Summary', 990, 110, '90%', 'Pipeline Build','trigger build'])
    thd = 20.0
    hello = "This is the test."
    hg.set_spec(hello,text_list,head_list,table_list,thd)
    hg.generate_html_report()
    
