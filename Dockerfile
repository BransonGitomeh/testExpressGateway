FROM mhart/alpine-node
WORKDIR /usr/src/app
RUN apk update && apk upgrade && \
    apk add --no-cache python make g++

RUN yarn global add nodemon parcel
COPY . .
RUN npm i
RUN npm run build
CMD node -r source-map-support/register dist
