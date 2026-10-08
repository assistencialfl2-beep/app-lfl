from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.spinner import Spinner
from kivy.uix.popup import Popup
from kivy.uix.togglebutton import ToggleButton
from kivy.core.window import Window
from kivy.utils import get_color_from_hex
import datetime
import webbrowser
import urllib.parse
import sqlite3
import os

# Fundo claro para o aplicativo
Window.clearcolor = get_color_from_hex('#F0F0F0')
# FAZ O ECRÃ SUBIR QUANDO O TECLADO APARECE PARA NÃO ESCONDER O TEXTO
Window.softinput_mode = 'below_target'

class OrdemServicoApp(App):
    def build(self):
        self.iniciar_base_dados()

        self.opcoes_servicos = {
            "Formatação": 100.00, 
            "Backup de Dados": 80.00, 
            "Limpeza Preventiva": 90.00, 
            "Troca de Peça": 50.00, 
            "Instalação de Programas": 60.00
        }
        self.servicos_selecionados = []

        layout = BoxLayout(orientation='vertical', padding=20, spacing=15)

        titulo = Label(text="LFL - INFORMÁTICA (v0.3.0)", size_hint=(1, 0.1), color=(0,0,0,1), bold=True)
        layout.add_widget(titulo)

        self.tipo = Spinner(text='Ordem de Serviço', values=('Ordem de Serviço', 'Orçamento'), size_hint=(1, 0.1), background_color=(0.8, 0.8, 0.8, 1), color=(0,0,0,1))
        layout.add_widget(self.tipo)

        self.nome = TextInput(hint_text='Nome do Cliente', multiline=False, size_hint=(1, 0.1), foreground_color=(0,0,0,1))
        layout.add_widget(self.nome)

        self.btn_servico = Button(text="Selecionar Serviços", size_hint=(1, 0.1), background_color=(0.9, 0.9, 0.9, 1), color=(0,0,0,1))
        self.btn_servico.bind(on_press=self.abrir_janela_servicos)
        layout.add_widget(self.btn_servico)

        hoje = datetime.datetime.now().strftime("%d/%m/%Y")
        self.data = TextInput(text=hoje, multiline=False, size_hint=(1, 0.1), foreground_color=(0,0,0,1))
        layout.add_widget(self.data)

        self.valor = TextInput(hint_text='Valor Total (R$)', multiline=False, size_hint=(1, 0.1), foreground_color=(0,0,0,1))
        layout.add_widget(self.valor)

        self.telefone = TextInput(hint_text='Telefone (com DDD, sem +)', multiline=False, size_hint=(1, 0.1), foreground_color=(0,0,0,1))
        layout.add_widget(self.telefone)

        btn_gerar = Button(text="Gerar Ordem e Enviar WhatsApp", size_hint=(1, 0.15), background_color=(0.1, 0.5, 0.8, 1), bold=True)
        btn_gerar.bind(on_press=self.gerar_ordem)
        layout.add_widget(btn_gerar)

        btn_buscar = Button(text="Buscar Ordem/Orçamento", size_hint=(1, 0.15), background_color=(0.7, 0.7, 0.7, 1), color=(0,0,0,1))
        btn_buscar.bind(on_press=self.abrir_janela_busca)
        layout.add_widget(btn_buscar)

        rodape = Label(text="Desenvolvido por Lysandro Luiz", size_hint=(1, 0.05), color=(0.4, 0.4, 0.4, 1), font_size=12)
        layout.add_widget(rodape)

        return layout

    def iniciar_base_dados(self):
        pasta_segura = self.user_data_dir
        caminho_db = os.path.join(pasta_segura, 'ordens_lfl.db')
        
        self.conn = sqlite3.connect(caminho_db)
        self.cursor = self.conn.cursor()
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS ordens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nome TEXT,
                tipo TEXT,
                servicos TEXT,
                data TEXT,
                valor TEXT,
                telefone TEXT
            )
        ''')
        self.conn.commit()

    def abrir_janela_servicos(self, instance):
        conteudo = BoxLayout(orientation='vertical', spacing=10, padding=10)
        
        scroll = ScrollView(size_hint=(1, 0.6))
        self.lista_botoes = GridLayout(cols=1, spacing=5, size_hint_y=None)
        self.lista_botoes.bind(minimum_height=self.lista_botoes.setter('height'))
        
        self.botoes_servicos = []
        for servico, preco in self.opcoes_servicos.items():
            texto_btn = f"{servico} - R$ {preco:.2f}".replace('.', ',')
            btn = ToggleButton(text=texto_btn, size_hint_y=None, height=100)
            btn.servico_nome = servico
            btn.servico_preco = preco
            
            if servico in self.servicos_selecionados:
                btn.state = 'down'
            self.botoes_servicos.append(btn)
            self.lista_botoes.add_widget(btn)
            
        scroll.add_widget(self.lista_botoes)
        conteudo.add_widget(scroll)
        
        box_novo = BoxLayout(orientation='horizontal', size_hint=(1, 0.15), spacing=5)
        self.input_novo_servico = TextInput(hint_text="Nome do serviço...", size_hint_x=0.5, multiline=False, foreground_color=(0,0,0,1))
        self.input_novo_preco = TextInput(hint_text="Valor", size_hint_x=0.3, multiline=False, foreground_color=(0,0,0,1))
        btn_add_novo = Button(text="+", size_hint_x=0.2, background_color=(0.1, 0.5, 0.8, 1), bold=True, font_size=30)
        btn_add_novo.bind(on_press=self.adicionar_novo_servico)
        
        box_novo.add_widget(self.input_novo_servico)
        box_novo.add_widget(self.input_novo_preco)
        box_novo.add_widget(btn_add_novo)
        conteudo.add_widget(box_novo)
        
        btn_confirmar = Button(text="Confirmar", size_hint=(1, 0.2), background_color=(0.1, 0.8, 0.1, 1), bold=True)
        btn_confirmar.bind(on_press=self.salvar_servicos)
        conteudo.add_widget(btn_confirmar)
        
        self.popup_servicos = Popup(title="Marque os Serviços e Valores", content=conteudo, size_hint=(0.95, 0.9))
        self.popup_servicos.open()

    def adicionar_novo_servico(self, instance):
        novo_servico = self.input_novo_servico.text.strip()
        preco_texto = self.input_novo_preco.text.strip().replace(',', '.')
        
        try:
            novo_preco = float(preco_texto) if preco_texto else 0.0
        except ValueError:
            novo_preco = 0.0

        if novo_servico and novo_servico not in self.opcoes_servicos:
            self.opcoes_servicos[novo_servico] = novo_preco
            
            texto_btn = f"{novo_servico} - R$ {novo_preco:.2f}".replace('.', ',')
            btn = ToggleButton(text=texto_btn, size_hint_y=None, height=100, state='down')
            btn.servico_nome = novo_servico
            btn.servico_preco = novo_preco
            
            self.botoes_servicos.append(btn)
            self.lista_botoes.add_widget(btn)
            
            self.input_novo_servico.text = ""
            self.input_novo_preco.text = ""

    def salvar_servicos(self, instance):
        self.servicos_selecionados = []
        valor_total = 0.0
        
        for btn in self.botoes_servicos:
            if btn.state == 'down':
                self.servicos_selecionados.append(btn.servico_nome)
                valor_total += btn.servico_preco
                
        self.popup_servicos.dismiss()
        
        if self.servicos_selecionados:
            self.btn_servico.text = f"{len(self.servicos_selecionados)} serviço(s) selecionado(s)"
            self.valor.text = f"R$ {valor_total:.2f}".replace('.', ',')
        else:
            self.btn_servico.text = "Selecionar Serviços"
            self.valor.text = ""

    def gerar_ordem(self, instance):
        nome_cliente = self.nome.text
        telefone = self.telefone.text
        tipo_ordem = self.tipo.text
        data_ordem = self.data.text
        valor = self.valor.text
        servicos_texto = ", ".join(self.servicos_selecionados) if self.servicos_selecionados else "Não especificado"

        self.cursor.execute('''
            INSERT INTO ordens (nome, tipo, servicos, data, valor, telefone)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (nome_cliente, tipo_ordem, servicos_texto, data_ordem, valor, telefone))
        self.conn.commit()

        numero_limpo = ''.join(filter(str.isdigit, telefone))
        if numero_limpo and len(numero_limpo) <= 11:
            numero_limpo = "55" + numero_limpo

        mensagem = f"Olá, *{nome_cliente}*!\n\nAqui estão os detalhes:\n📌 *Tipo:* {tipo_ordem}\n🛠️ *Serviço(s):* {servicos_texto}\n📅 *Data:* {data_ordem}\n💰 *Valor:* {valor}\n\nA LFL - Informática agradece!"
        texto_codificado = urllib.parse.quote(mensagem)

        if numero_limpo:
            link_whatsapp = f"https://wa.me/{numero_limpo}?text={texto_codificado}"
            webbrowser.open(link_whatsapp)

    def abrir_janela_busca(self, instance):
        conteudo = BoxLayout(orientation='vertical', spacing=10, padding=10)
        
        box_busca = BoxLayout(orientation='horizontal', size_hint=(1, 0.15), spacing=5)
        self.input_busca = TextInput(hint_text="Pesquisar por nome...", multiline=False, foreground_color=(0,0,0,1))
        btn_pesquisar = Button(text="Procurar", size_hint_x=0.4, background_color=(0.1, 0.5, 0.8, 1), bold=True)
        btn_pesquisar.bind(on_press=self.realizar_busca)
        
        box_busca.add_widget(self.input_busca)
        box_busca.add_widget(btn_pesquisar)
        conteudo.add_widget(box_busca)
        
        scroll = ScrollView(size_hint=(1, 0.7))
        self.lista_resultados = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.lista_resultados.bind(minimum_height=self.lista_resultados.setter('height'))
        
        scroll.add_widget(self.lista_resultados)
        conteudo.add_widget(scroll)
        
        btn_fechar = Button(text="Fechar", size_hint=(1, 0.15), background_color=(0.8, 0.1, 0.1, 1), bold=True)
        btn_fechar.bind(on_press=lambda x: self.popup_busca.dismiss())
        conteudo.add_widget(btn_fechar)
        
        self.popup_busca = Popup(title="Histórico de Clientes", content=conteudo, size_hint=(0.95, 0.9))
        self.popup_busca.open()
        
        self.realizar_busca(None)

    def realizar_busca(self, instance):
        self.lista_resultados.clear_widgets()
        termo = self.input_busca.text.strip()
        
        if termo:
            self.cursor.execute("SELECT tipo, nome, data, valor, servicos FROM ordens WHERE nome LIKE ? ORDER BY id DESC", ('%' + termo + '%',))
        else:
            self.cursor.execute("SELECT tipo, nome, data, valor, servicos FROM ordens ORDER BY id DESC LIMIT 15")
            
        resultados = self.cursor.fetchall()
        
        if not resultados:
            self.lista_resultados.add_widget(Label(text="Nenhum registo encontrado.", size_hint_y=None, height=40))
            return
            
        for res in resultados:
            tipo, nome, data, valor, servicos = res
            texto_botao = f"Cliente: {nome}\n{tipo} | Data: {data}\nValor: {valor}"
            btn = Button(text=texto_botao, size_hint_y=None, height=120, background_color=(0.2, 0.2, 0.2, 1))
            self.lista_resultados.add_widget(btn)

if __name__ == '__main__':
    OrdemServicoApp().run()