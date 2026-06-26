#ETAPA DE CREACION
#Imagen
FROM python:3.12-slim AS builder

#Directorio de trabajo
WORKDIR /app

#Instalar solo dependencias necesarias
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

#ETAPA DE EJECUCION
FROM python:3.12-slim AS runtime

LABEL maintainer="curso-devops"
LABEL descripcion="Estadisticas Service - Python"

WORKDIR /app

#Variables de entorno
ENV PATH=/home/appuser/.local/bin:$PATH

#Se cambia a usuario sin privilegios
#Crear usuario y grupo no privilegiados
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -d /home/appuser -m appuser

#Se traen las dependencias y los directorios en preparacion
#Se le asigna la propiedad a usuario (appuser) y no (root)
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .

#Aplicar el usuario
USER appuser

#Comunicacion del docker 
EXPOSE 8007

#Comprobacion de estado mediante peticion HTTP interna
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8007/live')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8007"]