var express = require('express')
var router = express.Router()
var signUpController = require('../controllers/signupController')

router.get('/', signUpController.signUp)

router.post('/confirmParticulars', function (req, res, next) {
  console.log(req.body)
  return res.status(200).json(req)
})

module.exports = router
