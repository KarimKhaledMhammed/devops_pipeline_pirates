# Use the unprivileged version to run as non-root by default
FROM nginxinc/nginx-unprivileged:alpine

# Copy custom Nginx config (optional but recommended for SPA/API routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static HTML file
COPY index.html /usr/share/nginx/html/index.html

# Expose the port Nginx is listening on (Unprivileged usually uses 8080)
EXPOSE 8080