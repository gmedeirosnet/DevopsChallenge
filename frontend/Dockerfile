FROM node:14.20.1-alpine3.15 as builder
WORKDIR /app
COPY ./app .
RUN npm install
RUN npm run build

FROM nginx:alpine as runner
COPY --from=builder /app/dist/letscodebyada-app /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]