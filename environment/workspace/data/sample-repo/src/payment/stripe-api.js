const axios = require('axios');

class StripeAPI {
    constructor (apiKey) {
        this.apiKey = apiKey;
    }

    async createCharge(amount) {
        return await axios.post('https://api.stripe.com/v1/charges', {
            amount: amount,
            currency: 'usd'
        });
    }
}

module.exports = StripeAPI;