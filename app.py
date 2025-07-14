from flask import Flask, render_template, request, redirect, flash, session, url_for
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from datetime import datetime
from datetime import timedelta
from functools import wraps
from flask_limiter import Limiter
from dotenv import load_dotenv
import os
import re
import mysql.connector
import oracledb


# Carregar variáveis do .env
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', '8c40aecf80f183d52668c100b99424c2b0bfa49c617bcc88')
#comando no terminal para gerar a chave de segurança fora do container: python3 -c "import os; print(os.urandom(24).hex())"

# Limite de requisições
limiter = Limiter(app)

#logout automatico
app.permanent_session_lifetime = timedelta(minutes=15)

# Conexão com MySQL
def get_db_connection():
    return mysql.connector.connect(
        host='db',
        user='root',
        password=os.getenv('MYSQL_ROOT_PASSWORD', 'senha_default'),
        database=os.getenv('MYSQL_DATABASE', 'ged')
    )

# Conexão com Oracle
def get_oracle_connection():
    return oracledb.connect(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        dsn=os.getenv("DB_DSN")
    )

# Tratamento de erro de limite de requisição
@app.errorhandler(429)
def ratelimit_handler(e):
    retry_after = e.retry_after or 60
    return f'Tentativas excedidas. Tente novamente em {retry_after} segundos.', 429

# Tratamento de erro 404
@app.errorhandler(404)
def page_not_found(e):
    flash('Página não encontrada. Você foi redirecionado para a tela inicial.', 'warning')
    return redirect('/home')

def login_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash('Sessão expirada ou não autenticada. Faça login novamente.')
            return redirect(url_for('login'))
        return func(*args, **kwargs)
    return decorated_function

@app.route('/', methods=['GET', 'POST'])
@limiter.limit("10 per minute")
def login():
    next_url = request.args.get('next') if request.method == 'GET' else request.form.get('next')

    if request.method == 'POST':
        login = request.form['login']
        senha = request.form['senha']

        conn = None
        try:
            conn = get_db_connection()
            with conn.cursor(dictionary=True) as cursor:
                cursor.execute("SELECT * FROM usuarios WHERE login = %s AND status = 'A'", (login,))
                user = cursor.fetchone()

                if user:
                    if check_password_hash(user['senha'], senha):
                        session['user_id'] = user['id']
                        session['user_tipo'] = user['tipo']
                        session['user_login'] = user['login']
                        session.permanent = True #logout automatico

                        cursor.execute("""
                            INSERT INTO log_acesso (login, tipo_acesso)
                            VALUES (%s, 'V')
                        """, (login,))
                        conn.commit()

                        flash('Login efetuado com sucesso!')
                        #return redirect(next_url) if next_url and next_url.startswith('/') else redirect(url_for('home'))
                        response = redirect(next_url) if next_url and next_url.startswith('/') else redirect(url_for('home'))

                        # Se checkbox estiver marcado, gravar login no cookie por 30 dias
                        if 'lembrar_login' in request.form:
                            response.set_cookie('login_salvo', login, max_age=30*24*60*60)
                        else:
                            response.set_cookie('login_salvo', '', max_age=0)

                        return response

                    else:
                        cursor.execute("""
                            INSERT INTO log_acesso (login, tipo_acesso)
                            VALUES (%s, 'F')
                        """, (login,))
                        conn.commit()
                        flash("Senha incorreta.")
                        return redirect(url_for('login', next=next_url))
                else:
                    cursor.execute("""
                        INSERT INTO log_acesso (login, tipo_acesso)
                        VALUES (%s, 'F')
                    """, (login,))
                    conn.commit()
                    flash("Usuário não encontrado ou inativo.")
                    return redirect(url_for('login', next=next_url))

        except Exception as e:
            flash(f'Erro no banco de dados: {e}')
            return redirect(url_for('login'))
        finally:
            if conn:
                conn.close()

    return render_template('login.html', next=next_url)


@app.route('/logout')
def logout():
    session.clear()
    flash('Logout realizado.')
    return redirect(url_for('login'))


@app.before_request
def renovar_sessao():
    session.permanent = True

@app.route('/home')
def home():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return render_template('home.html')

# Cadastro de Usuários
@app.route('/usuarios', methods=['GET', 'POST'])
@login_required
def usuarios():
    if 'user_tipo' not in session or session['user_tipo'] != 'Administrador':
        flash('Acesso negado.')
        return redirect('/home')

    nome = request.args.get('nome') #busca usuario por nome

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # POST Criar ou Editar usuário
    if request.method == 'POST':
        user_id = request.form.get('user_id')
        nome = request.form['nome']
        login = request.form['login']
        email = request.form['email']
        empresa_id = request.form['empresa_id']
        tipo = request.form['tipo']
        senha = request.form.get('senha')
        status = request.form.get('status', 'A')

        if user_id:  # Editar Usuário
            if senha:
                senha_hash = generate_password_hash(senha)
                cursor.execute("""
                    UPDATE usuarios SET nome=%s, login=%s, email=%s, empresa_id=%s, tipo=%s, senha=%s, status=%s WHERE id=%s
                """, (nome, login, email, empresa_id, tipo, senha_hash, status, user_id))
            else:
                cursor.execute("""
                    UPDATE usuarios SET nome=%s, login=%s, email=%s, empresa_id=%s, tipo=%s, status=%s WHERE id=%s
                """, (nome, login, email, empresa_id, tipo, status, user_id))
            flash('Usuário atualizado.')
        else:  # Novo Usuário
            senha_hash = generate_password_hash(senha)
            cursor.execute("""
                INSERT INTO usuarios (nome, login, email, empresa_id, senha, tipo, status) VALUES (%s, %s, %s, %s, %s, %s, 'A')
            """, (nome, login, email, empresa_id, senha_hash, tipo))
            flash('Usuário cadastrado.')

        conn.commit()
        return redirect('/usuarios')

    # GET para inativar, ativar, redefinir senha usuário
    inativar_id = request.args.get('inativar')
    ativar_id = request.args.get('ativar')
    redefinir_id = request.args.get('redefinir')

    if inativar_id:
        cursor.execute("UPDATE usuarios SET status='I' WHERE id=%s", (inativar_id,))
        conn.commit()
        flash('Usuário inativado.')
        return redirect('/usuarios')

    if ativar_id:
        cursor.execute("UPDATE usuarios SET status='A' WHERE id=%s", (ativar_id,))
        conn.commit()
        flash('Usuário ativado.')
        return redirect('/usuarios')

    if redefinir_id:
        nova_senha = '123456'
        senha_hash = generate_password_hash(nova_senha)
        cursor.execute("UPDATE usuarios SET senha=%s WHERE id=%s", (senha_hash, redefinir_id))
        conn.commit()
        flash(f'Senha redefinida para: {nova_senha}')
        return redirect('/usuarios')

    # Para editar usuário via parâmetro
    editar_id = request.args.get('editar')
    usuario_editar = None
    if editar_id:
        cursor.execute("SELECT * FROM usuarios WHERE id=%s", (editar_id,))
        usuario_editar = cursor.fetchone()

    if nome:
        cursor.execute("SELECT * FROM usuarios WHERE nome LIKE %s", ('%' + nome + '%',))
    else:
        cursor.execute("SELECT * FROM usuarios")
    usuarios = cursor.fetchall()


    # Buscar empresas para popular campo seleção empresa cadastro usuario
    cursor.execute("SELECT * FROM empresas WHERE status = 'A' ORDER BY nome")
    empresas = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('usuarios.html', usuarios=usuarios, usuario_editar=usuario_editar, empresas=empresas, nome=nome)

# Rota alterar senha pelo usuario
@app.route('/alterar_senha', methods=['GET', 'POST'])
@login_required
def alterar_senha():
    if request.method == 'POST':
        senha_atual = request.form['senha_atual']
        nova_senha = request.form['nova_senha']
        confirmar_senha = request.form['confirmar_senha']

        user_id = session['user_id']

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT senha FROM usuarios WHERE id = %s", (user_id,))
        usuario = cursor.fetchone()

        if not usuario or not check_password_hash(usuario['senha'], senha_atual):
            flash('Senha atual incorreta.', 'danger')
        elif nova_senha != confirmar_senha:
            flash('A nova senha e a confirmação não coincidem.', 'warning')
        elif len(nova_senha) < 6:
            flash('A nova senha deve ter ao menos 6 caracteres.', 'warning')
        elif not re.match(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$', nova_senha):
            flash('A senha deve conter ao menos 8 caracteres, incluindo letras e números.', 'warning')
        else:
            nova_senha_hash = generate_password_hash(nova_senha)
            cursor.execute("UPDATE usuarios SET senha = %s WHERE id = %s", (nova_senha_hash, user_id))
            conn.commit()
            flash('Senha alterada com sucesso!', 'success')
            return redirect('/home')

        cursor.close()
        conn.close()

    return render_template('alterar_senha.html')

# Rota Empresas
@app.route('/empresas', methods=['GET', 'POST'])
@login_required #Chama a função que requer LOGIN
def empresas():

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Ativar empresa via query string
    empresa_id_ativar = request.args.get('ativar')
    if empresa_id_ativar:
        cursor.execute("UPDATE empresas SET status = 'A' WHERE id = %s", (empresa_id_ativar,))
        conn.commit()
        flash('Empresa ativada com sucesso.')
        cursor.close()
        conn.close()
        return redirect('/empresas')

    # Inativar empresa via query string
    empresa_id_inativar = request.args.get('inativar')
    if empresa_id_inativar:
        cursor.execute("UPDATE empresas SET status = 'I' WHERE id = %s", (empresa_id_inativar,))
        conn.commit()
        flash('Empresa inativada com sucesso.')
        cursor.close()
        conn.close()
        return redirect('/empresas')

    # Editar empresa (GET para buscar dados)
    empresa_editar = None
    empresa_id_editar = request.args.get('editar')
    if empresa_id_editar:
        cursor.execute("SELECT * FROM empresas WHERE id = %s", (empresa_id_editar,))
        empresa_editar = cursor.fetchone()

    # POST para inserir ou atualizar empresa
    if request.method == 'POST':
        empresa_id = request.form.get('empresa_id')
        nome = request.form['nome']
        descricao = request.form['descricao']

        if empresa_id:  # Atualizar empresa existente
            cursor.execute("""
                UPDATE empresas SET nome = %s, descricao = %s WHERE id = %s
            """, (nome, descricao, empresa_id))
            flash('Empresa atualizada com sucesso.')
        else:  # Inserir nova empresa
            cursor.execute("""
                INSERT INTO empresas (nome, descricao, status) VALUES (%s, %s, 'A')
            """, (nome, descricao))
            flash('Empresa adicionada com sucesso.')

        conn.commit()
        cursor.close()
        conn.close()
        return redirect('/empresas')

    # Listar todas as empresas, ativas e inativas
    cursor.execute("SELECT * FROM empresas ORDER BY nome")
    empresas = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('empresas.html', empresas=empresas, empresa_editar=empresa_editar)

# Rota cadastro pessoa fisica e lista pessoas cadastradas
@app.route('/pessoa_fisica', methods=['GET', 'POST'])
@login_required
def pessoa_fisica(): 
    pessoa = None
    lista_pessoas = []

    if request.method == 'POST':
        acao = request.form.get('acao')
        cd_pessoa_fisica = request.form.get('cd_pessoa_fisica')

        if not cd_pessoa_fisica:
            flash('Código da pessoa física é obrigatório.', 'warning')
            return redirect(url_for('pessoa_fisica'))

        try:
            if acao == 'buscar':
                # Consulta Oracle
                oracle_conn = get_oracle_connection()
                oracle_cursor = oracle_conn.cursor()

                oracle_cursor.execute("""
                    SELECT cd_pessoa_fisica,
                           nm_pessoa_fisica,
                           nr_prontuario
                    FROM pessoa_fisica
                    WHERE cd_pessoa_fisica = :1
                """, [cd_pessoa_fisica])

                result = oracle_cursor.fetchone()
                oracle_cursor.close()
                oracle_conn.close()

                if not result:
                    flash('Pessoa não encontrada no Oracle.', 'warning')
                else:
                    pessoa = {
                        'cd_pessoa_fisica': result[0],
                        'nome_pessoa_fisica': result[1],
                        'nr_prontuario': result[2]
                    }

            elif acao == 'confirmar':
                nome_pessoa_fisica = request.form.get('nome_pessoa_fisica')
                nr_prontuario = request.form.get('nr_prontuario')
                login_usuario = session.get('user_login')

                mysql_conn = get_db_connection()
                mysql_cursor = mysql_conn.cursor()

                try:
                    mysql_cursor.execute("""
                        INSERT INTO pessoa_fisica (cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario, login)
                        VALUES (%s, %s, %s, %s)
                    """, (cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario, login_usuario))
                    mysql_conn.commit()
                    flash('Pessoa cadastrada com sucesso.', 'success')
                except mysql.connector.errors.IntegrityError:
                    flash('Pessoa já cadastrada no sistema.', 'info')
                finally:
                    mysql_cursor.close()
                    mysql_conn.close()

        except Exception as e:
            flash(f'Ocorreu um erro: {e}', 'danger')

    # Consulta sempre a lista de cadastrados no MySQL
    try:
        mysql_conn = get_db_connection()
        mysql_cursor = mysql_conn.cursor(dictionary=True)
        mysql_cursor.execute("""
            SELECT id_pessoa_fisica, cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario,
                   cd_pessoa_fisica_anterior, nr_prontuario_alterior, dt_criacao, dt_atualizacao, login
            FROM pessoa_fisica
        """)
        lista_pessoas = mysql_cursor.fetchall()
        mysql_cursor.close()
        mysql_conn.close()
    except Exception as e:
        flash(f'Erro ao carregar lista de pessoas cadastradas: {e}', 'danger')

    return render_template('pessoa_fisica.html', pessoa=pessoa, lista_pessoas=lista_pessoas)


@app.route('/pessoas_cadastradas')
@login_required
def pessoas_cadastradas():
    lista_pessoas = []
    try:
        mysql_conn = get_db_connection()
        mysql_cursor = mysql_conn.cursor(dictionary=True)

        mysql_cursor.execute("""
            SELECT id_pessoa_fisica, cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario,
                   cd_pessoa_fisica_anterior, nr_prontuario_alterior
            FROM pessoa_fisica
        """)
        lista_pessoas = mysql_cursor.fetchall()

        mysql_cursor.close()
        mysql_conn.close()

    except Exception as e:
        flash(f'Erro ao buscar pessoas: {e}', 'danger')

    return render_template('pessoas_cadastradas.html', lista_pessoas=lista_pessoas)


# Rota criação grupos de documentos e pastas
@app.route('/grupo_pasta', methods=['GET', 'POST'])
@login_required
def grupo_pasta():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        ds_grupo_documento = request.form['ds_grupo_documento']
        id_grupo_pai = request.form.get('id_grupo_pai') or None
        id_usuario_cadastro = session.get('user_id')
        login_usuario = session.get('user_login')

        cursor.execute("""
            INSERT INTO grupo_pasta (ds_grupo_documento, grupo_pai_id, id_usuario_cadastro, login)
            VALUES (%s, %s, %s, %s)
        """, (ds_grupo_documento, id_grupo_pai, id_usuario_cadastro, login_usuario))
        conn.commit()
        flash('Grupo de documentos criado com sucesso.')
        return redirect(url_for('grupo_pasta'))

    # Busca todos os grupos com nome do pai (caso exista)
    cursor.execute("""
        SELECT gp.*, pai.ds_grupo_documento AS nome_pai
        FROM grupo_pasta gp
        LEFT JOIN grupo_pasta pai ON gp.grupo_pai_id = pai.id_grupo_documento
        ORDER BY gp.ds_grupo_documento
    """)
    grupos = cursor.fetchall()

    # Grupos principais para o select de pai
    cursor.execute("""
        SELECT id_grupo_documento, ds_grupo_documento
        FROM grupo_pasta
        WHERE grupo_pai_id IS NULL
        ORDER BY ds_grupo_documento
    """)
    grupos_pai = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('grupo_pasta.html', grupos=grupos, grupos_pai=grupos_pai)


# Caminho absoluto da pasta de uploads
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'uploads')
ALLOWED_EXTENSIONS = {'pdf'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
#se o arquino não for gerado em /static/uploads dê chmod + 777 /static/uploads
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# Rota Upload dearquivos
@app.route('/upload_documento', methods=['GET', 'POST'])
@login_required
def upload_documento():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    nome_pessoa = None
    cd_pessoa_fisica = None

    if request.method == 'POST':
        acao = request.form.get('acao')
        cd_pessoa_fisica = request.form.get('cd_pessoa_fisica', '').strip()

        if acao == 'buscar':
            cursor.execute("SELECT nome_pessoa_fisica FROM pessoa_fisica WHERE cd_pessoa_fisica = %s", (cd_pessoa_fisica,))
            pessoa = cursor.fetchone()
            if pessoa:
                nome_pessoa = pessoa['nome_pessoa_fisica']
            else:
                #flash('Pessoa física não encontrada.', 'danger')
                flash('Pessoa física não encontrada. <a href="http://192.168.25.7:7050/pessoa_fisica" class="alert-link" target="_blank">Clique aqui para Cadastrar</a>.', 'danger')

        elif acao == 'upload':
            id_grupo = request.form['id_grupo_documento']
            file = request.files.get('file')
            login_usuario = session.get('user_login')

            # Verificar se pessoa ainda existe
            cursor.execute("SELECT 1 FROM pessoa_fisica WHERE cd_pessoa_fisica = %s", (cd_pessoa_fisica,))
            if not cursor.fetchone():
                flash('Código de pessoa física inválido.', 'danger')
                return redirect(request.url)

            if not file or file.filename == '':
                flash('Nenhum arquivo selecionado.', 'danger')
                return redirect(request.url)

            if not allowed_file(file.filename):
                flash('Apenas arquivos PDF são permitidos.', 'danger')
                return redirect(request.url)

            filename = secure_filename(file.filename)
            pasta_destino = os.path.join(app.config['UPLOAD_FOLDER'], cd_pessoa_fisica, id_grupo)

            try:
                os.makedirs(pasta_destino, exist_ok=True)
            except Exception as e:
                flash('Erro ao criar diretório de upload.', 'danger')
                return redirect(request.url)

            caminho_arquivo = os.path.join(pasta_destino, filename)

            try:
                file.save(caminho_arquivo)
            except Exception as e:
                flash('Erro ao salvar o arquivo.', 'danger')
                return redirect(request.url)

            cursor.execute("""
                INSERT INTO documentos (cd_pessoa_fisica, id_grupo_documento, nome_arquivo, caminho_arquivo, login)
                VALUES (%s, %s, %s, %s, %s)
            """, (cd_pessoa_fisica, id_grupo, filename, os.path.relpath(caminho_arquivo, BASE_DIR), login_usuario))
            conn.commit()

            flash('Arquivo enviado com sucesso.', 'success')
            return redirect(url_for('upload_documento'))

    # Buscar grupos de pastas
    cursor.execute("""
        SELECT id_grupo_documento, ds_grupo_documento
        FROM grupo_pasta
        WHERE status = 'A'
        ORDER BY ds_grupo_documento
    """)
    pastas = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('upload_documento.html', pastas=pastas, nome_pessoa=nome_pessoa, cd_pessoa_fisica=cd_pessoa_fisica)


# Rota Excluir documento anexado
@app.route('/excluir_documento/<int:documento_id>', methods=['POST'])
@login_required
def excluir_documento(documento_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT caminho_arquivo FROM documentos WHERE id_documento = %s", (documento_id,))
    doc = cursor.fetchone()

    if doc:
        try:
            os.remove(doc['caminho_arquivo'])
        except FileNotFoundError:
            pass

        cursor.execute("DELETE FROM documentos WHERE id_documento = %s", (documento_id,))
        conn.commit()
        flash('Documento excluído com sucesso.', 'success')
    else:
        flash('Documento não encontrado.', 'danger')

    cursor.close()
    conn.close()
    return redirect(request.referrer)


# Rota visualização dos arquivos no Tasy
# Parâmetros PEP - URL para o GED: http://192.168.25.7:7050/viewer?codigo=$CD_PESSOA_FISICA
# Rota pública
@app.route('/viewer')
def viewer():
    cd_pessoa_fisica = request.args.get('codigo')
    if not cd_pessoa_fisica:
        return "Código da pessoa física não informado.", 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Buscar grupos de pastas
    cursor.execute("""
        SELECT id_grupo_documento, ds_grupo_documento, grupo_pai_id
        FROM grupo_pasta
        WHERE status = 'A'
        ORDER BY ds_grupo_documento
    """)
    grupos = cursor.fetchall()

    # Buscar nome da pessoa
    cursor.execute("""
        SELECT nome_pessoa_fisica
        FROM pessoa_fisica
        WHERE cd_pessoa_fisica = %s
    """, (cd_pessoa_fisica,))
    pessoa = cursor.fetchone()
    nome_pessoa = pessoa['nome_pessoa_fisica'] if pessoa else f"Cód: {cd_pessoa_fisica}"

        # Buscar documentos do paciente
    cursor.execute("""
        SELECT id_documento, id_grupo_documento, nome_arquivo, caminho_arquivo, dt_upload
        FROM documentos
        WHERE cd_pessoa_fisica = %s
    """, (cd_pessoa_fisica,))
    documentos = cursor.fetchall()

    estrutura = montar_estrutura_pastas(grupos, documentos)

    cursor.close()
    conn.close()

    #return render_template('viewer.html', estrutura=estrutura, cd_pessoa_fisica=cd_pessoa_fisica)
    return render_template('viewer.html', estrutura=estrutura, nome_pessoa=nome_pessoa)


def montar_estrutura_pastas(grupos, documentos):
    def filhos(pai_id):
        return [g for g in grupos if g['grupo_pai_id'] == pai_id]

    def montar_no(grupo):
        return {
            'id': grupo['id_grupo_documento'],
            'nome': grupo['ds_grupo_documento'],
            'filhos': [montar_no(g) for g in filhos(grupo['id_grupo_documento'])],
            'documentos': [d for d in documentos if d['id_grupo_documento'] == grupo['id_grupo_documento']]
        }

    raizes = [g for g in grupos if g['grupo_pai_id'] is None]
    return [montar_no(g) for g in raizes]

# Rota ver todos os documentos da pessoa fisica
@app.route('/documentos/<int:cd_pessoa_fisica>')
@login_required
def documentos_por_pessoa(cd_pessoa_fisica):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # 1. Buscar nome da pessoa
    cursor.execute("""
        SELECT nome_pessoa_fisica
        FROM pessoa_fisica
        WHERE cd_pessoa_fisica = %s
    """, (cd_pessoa_fisica,))
    pessoa = cursor.fetchone()
    nome_pessoa = pessoa['nome_pessoa_fisica'] if pessoa else f"Cód: {cd_pessoa_fisica}"

    # 2. Buscar documentos da pessoa
    cursor.execute("""
        SELECT *
        FROM documentos
        WHERE cd_pessoa_fisica = %s
    """, (cd_pessoa_fisica,))
    documentos = cursor.fetchall()

    # 3. Buscar todas as pastas
    cursor.execute("""
        SELECT *
        FROM grupo_pasta
    """)
    grupos = cursor.fetchall()

    cursor.close()
    conn.close()

    # 4. Montar estrutura hierárquica
    estrutura = montar_estrutura_pastas(grupos, documentos)

    # 5. Renderizar
    return render_template(
        'documentos.html',
        grupos=estrutura,
        nome_pessoa=nome_pessoa
    )


# Rota atualiza código de pessoa fisica para atender a necessiade de unificação de cadastros
@app.route('/atualizar_codigo_pessoa', methods=['GET', 'POST'])
@login_required
def atualizar_codigo_pessoa():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    pessoa = None

    if request.method == 'POST':
        acao = request.form.get('acao')

        if acao == 'buscar':
            cd_pessoa = request.form.get('cd_pessoa_fisica')

            cursor.execute("""
                SELECT cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario, dt_criacao
                FROM pessoa_fisica
                WHERE cd_pessoa_fisica = %s
            """, (cd_pessoa,))
            pessoa = cursor.fetchone()

            if not pessoa:
                flash('Pessoa física não encontrada. <a href="http://192.168.25.7:7050/pessoa_fisica" class="alert-link" target="_blank">Clique aqui para Cadastrar</a>.', 'danger')
            else:
                flash('Pessoa física encontrada. Valide os dados par aprocveder com a atualização do novo código abaixo.', 'info')

        elif acao == 'atualizar':
            antigo_codigo = request.form.get('codigo_antigo')
            novo_codigo = request.form.get('novo_cd_pessoa_fisica')

            # Verifica se novo código já existe
            cursor.execute("SELECT 1 FROM pessoa_fisica WHERE cd_pessoa_fisica = %s", (novo_codigo,))
            if cursor.fetchone():
                flash('O novo código informado já está em uso.', 'danger')
            else:
                # Atualiza a pessoa_fisica
                cursor.execute("""
                    UPDATE pessoa_fisica
                    SET cd_pessoa_fisica = %s,
                        cd_pessoa_fisica_anterior = %s,
                        dt_atualizacao = %s
                    WHERE cd_pessoa_fisica = %s
                """, (novo_codigo, antigo_codigo, datetime.now(), antigo_codigo))

                # Atualiza a tabela documentos
                cursor.execute("""
                    UPDATE documentos
                    SET cd_pessoa_fisica = %s
                    WHERE cd_pessoa_fisica = %s
                """, (novo_codigo, antigo_codigo))

                conn.commit()
                flash('Código da pessoa física atualizado com sucesso.', 'success')
                return redirect(url_for('atualizar_codigo_pessoa'))

    cursor.close()
    conn.close()
    return render_template('atualizar_codigo_pessoa.html', pessoa=pessoa)


# Rota Ocupação Hospitalar. Visualiza pacientes internados.
@app.route('/ocupacao_hospitalar')
def listar_ocupacao():
    oracle_conn = get_oracle_connection()
    oracle_cursor = oracle_conn.cursor()

    query = """
        SELECT 
            a.cd_pessoa_fisica,
            (SELECT nm_pessoa_fisica FROM pessoa_fisica WHERE cd_pessoa_fisica = a.cd_pessoa_fisica) nm_paciente,
            (select nr_prontuario from pessoa_fisica where cd_pessoa_fisica = a.cd_pessoa_fisica) nr_prontuario,
            o.cd_setor_atendimento,
            o.ds_setor_atendimento,
            o.nr_atendimento,
            a.dt_entrada dt_internacao
        FROM ocupacao_hospitalar o 
        JOIN atendimento_paciente a ON o.nr_atendimento = a.nr_atendimento
        WHERE o.ie_ocupada = 1 AND o.cd_tipo_acomodacao <> 0
        AND o.ie_situacao_unidade = 'A'
        ORDER BY o.ds_setor_atendimento, 2
    """

    oracle_cursor.execute(query)
    resultados = oracle_cursor.fetchall()

    colunas = [desc[0].lower() for desc in oracle_cursor.description]  # nomes das colunas em minúsculo
    dados = [dict(zip(colunas, row)) for row in resultados]

    oracle_cursor.close()
    oracle_conn.close()

    return render_template("ocupacao_hospitalar.html", dados=dados)

# Função para Cadastro automático dos pacientes internados.
# Roda via job ou sincronizar_pacientes com log em /log_sincronizacao
#from datetime import datetime

def sincronizar_pacientes_oracle_para_mysql2():
    log_msgs = []
    oracle_conn = oracle_cursor = None
    mysql_conn = mysql_cursor = None

    try:
        oracle_conn = get_oracle_connection()
        oracle_cursor = oracle_conn.cursor()

        oracle_cursor.execute("""
            SELECT a.cd_pessoa_fisica,
                (SELECT pf.nm_pessoa_fisica FROM pessoa_fisica pf WHERE pf.cd_pessoa_fisica = a.cd_pessoa_fisica) AS nm_paciente,
                (SELECT pf.nr_prontuario FROM pessoa_fisica pf WHERE pf.cd_pessoa_fisica = a.cd_pessoa_fisica) AS nr_prontuario
            FROM ocupacao_hospitalar o
            JOIN atendimento_paciente a ON o.nr_atendimento = a.nr_atendimento
            WHERE o.ie_ocupada = 1 AND o.cd_tipo_acomodacao <> 0 
            AND o.ie_situacao_unidade = 'A'
        """)
        pacientes_oracle = oracle_cursor.fetchall()

        mysql_conn = get_db_connection()
        mysql_cursor = mysql_conn.cursor()

        total_inseridos = 0
        for cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario in pacientes_oracle:
            if cd_pessoa_fisica is None:
                continue

            mysql_cursor.execute("SELECT 1 FROM pessoa_fisica WHERE cd_pessoa_fisica = %s", (cd_pessoa_fisica,))
            if mysql_cursor.fetchone():
                log_msgs.append(f"[IGNORADO] Já cadastrado: {cd_pessoa_fisica} - {nome_pessoa_fisica}")
                continue

            mysql_cursor.execute("""
                INSERT INTO pessoa_fisica (cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario, login)
                VALUES (%s, %s, %s, %s)
            """, (cd_pessoa_fisica, nome_pessoa_fisica, nr_prontuario, 'job'))
            total_inseridos += 1
            log_msgs.append(f"[INSERIDO] {cd_pessoa_fisica} - {nome_pessoa_fisica}")

        mysql_conn.commit()
        log_msgs.append(f"Sincronização concluída. Total inseridos: {total_inseridos}")

    except Exception as e:
        log_msgs.append(f"[ERRO] Erro ao sincronizar pacientes: {e}")

    finally:
        if oracle_cursor: oracle_cursor.close()
        if oracle_conn: oracle_conn.close()
        if mysql_cursor: mysql_cursor.close()
        if mysql_conn: mysql_conn.close()

        # Escrever log
        log_path = "/opt/ged/logs/sincronizar.log"
        with open(log_path, 'a') as log_file:
            log_file.write(f"\n--- {datetime.now().strftime('%d-%m-%Y %H:%M:%S')} ---\n")
            for msg in log_msgs:
                log_file.write(msg + "\n")

    return f"{total_inseridos} pacientes foram cadastrados com sucesso."


# Rota para sincronizar pacientes manualmente
@app.route('/sincronizar_pacientes', methods=['GET', 'POST'])
@login_required
def sincronizar_pacientes():
    mensagem = None
    if request.method == 'POST':
        mensagem = sincronizar_pacientes_oracle_para_mysql()
    return render_template('sincronizar_pacientes.html', mensagem=mensagem)

# Rota ver página de log de sincronismo. 2h da manha gera
@app.route('/log_sincronizacao')
@login_required
def log_sincronizacao():
    log_path = '/opt/ged/logs/sincronizar.log'
    log_backup_path = '/opt/ged/logs/log_backup.log'

    def ler_log(caminho):
        if os.path.exists(caminho):
            with open(caminho, 'r') as f:
                return f.readlines()
        return []

    log_atual = ler_log(log_path)
    log_backup = ler_log(log_backup_path)

    return render_template(
        'log_sincronizacao.html',
        log_atual=log_atual[::-1],   # Mais recentes no topo
        log_backup=log_backup[::-1]
    )


@app.route('/log_sincronizacao2')
@login_required
def log_sincronizacao2():
    log_path = '/opt/ged/logs/sincronizar.log'
    log_backup_path = '/opt/ged/logs/log_backup.log'
    linhas_por_pagina = 100
    pagina = int(request.args.get('pagina', 1))

    if not os.path.exists(log_path):
        return "Log não encontrado.", 404

    with open(log_path, 'r') as f:
        linhas = f.readlines()

    total_linhas = len(linhas)
    total_paginas = (total_linhas + linhas_por_pagina - 1) // linhas_por_pagina

    inicio = max(total_linhas - pagina * linhas_por_pagina, 0)
    fim = total_linhas - (pagina - 1) * linhas_por_pagina
    linhas_pagina = linhas[inicio:fim]

    return render_template(
        'log_sincronizacao.html',
        linhas=linhas_pagina[::-1],  # Inverter: mais recentes no topo, facilita na visualização do log que ainda não tem quebra por data.
        pagina=pagina,
        total_paginas=total_paginas
    )


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6000, debug=True)
