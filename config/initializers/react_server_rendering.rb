# To render React components in production, precompile the server rendering manifest:
Rails.application.config.assets.precompile += ["standalone/server_rendering.js"]
