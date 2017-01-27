# hubot-unpkg
A hubot script that provieds get the unpkg url of package and will get the message of the new version when the packges is updated.

See [`src/unpkg.coffee`](src/unpkg.coffee) for full documentation.

## Installation

run:
`npm install hubot-unpkg --save`

Then add **hubot-unpkg** to your `external-scripts.json`:

```json
[
  "hubot-unpkg"
]
```

## Sample Interaction

```
user1>> unpkg vue
hubot>> https://unpkg.com/vue@2.1.10
```

## NPM Module

https://www.npmjs.com/package/hubot-unpkg
