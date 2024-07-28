# MoodiSense
This app is a part of the prototype for getting adaptive music recommendations based on physiological data.
With an Spotify Premium Account it can be experienced here: https://changeyourmood.vercel.app

This app is not released in AppStore.

## MoodiSense for watchOS
This app will receive the physiological data and send it to the iOS companion app.

## MoodiSense for iOS
This app will receive the data from watchOS app and send it to OpenAI.
OpenAI is going to derive an energy level with the ability of function calling.

To get it work, an individual OpenAI API token must be integrated in CYM/Secrets.swift.
To get a token, you have to create a new project and create a token based on that.

You can create a token here: https://platform.openai.com/docs/overview 


