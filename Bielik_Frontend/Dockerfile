FROM python:3.12

WORKDIR /bielik_frontend
ADD ./requirements.txt /bielik_frontend/
ADD ./bielik_frontend.py /bielik_frontend/
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000
ENV FLASK_APP=bielik_frontend

CMD ["gunicorn","--workers","3","bielik_frontend:app","--bind","0.0.0.0:5000"]