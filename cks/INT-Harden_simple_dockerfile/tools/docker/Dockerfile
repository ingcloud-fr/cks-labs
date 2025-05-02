# ❌ Insecure version to be improved
FROM python
RUN apt-get update
RUN apt-get -y install curl
RUN apt-get clean
COPY main.py /app/main.py
WORKDIR /app
ENV SECRET=2e064aad-3a90-4cde-ad86-16fad1f8943e
CMD ["python", "-u", "main.py"]
