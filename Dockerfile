FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
#RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt
COPY . .

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 6000

CMD ["python", "app.py"]

COPY templates/ templates/
