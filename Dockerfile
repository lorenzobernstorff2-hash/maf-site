FROM nginx:alpine
COPY nginx-default.conf /etc/nginx/conf.d/default.conf
# Só o que é público entra no site, por lista: arquivo novo na raiz do repo
# (documento interno, script, teste) não vai parar no domínio sem querer.
COPY *.html styles.css script.js robots.txt sitemap.xml /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/
COPY materiais/ /usr/share/nginx/html/materiais/
EXPOSE 80
