## Зависимости
nodemailer       = require 'nodemailer'
smtpPool         = require 'nodemailer-smtp-pool'
_                = require 'lodash'
credentials      = require '../../smtp.json'
fs               = require 'fs'

config  =
  logger: true
  maxConnections: 2
  maxMessages: 1000
  rateLimit: 1
  service: 'yandex'
  auth: credentials

transport = nodemailer.createTransport smtpPool(config)

mailOptions =
  from: "Feedback robot <#{credentials.user}>"
  to: "getstarted@makeomatic.ru"

# кеш внутри памяти -- мы не хотим получать много спама, но и мучаться писать защиты тоже не хотим
# просто сохраняем все запросы внутри памяти и периодически чистим
cache =
  phones: {}

# чистим каждые 6 часов
# oneDay = 86400000
# setInterval (-> cache.phones = {}), oneDay/4

exports.brief = (req, res)->
  ## Здесь обрабатываем заявки на поступающие запросы
  {name, phone, email, question} = req.body

  if req.files?
    {qqfile} = req.files

  # если в кеше уже присутствует телефон - не шлем еще раз
  # return res.json {success: true} if cache.phones[cachedPhone]?

  # делаем аналогичные клиенту проверки
  errors = []
  errors.push res.__("Укажите Ваше имя и фамилию") if name.length < 4
  errors.push res.__("Укажите ваш номер полностью") if (cachedPhone = phone.replace(/\D/g, "")).length < 11
  return res.json {success:false, errors}, 400 if errors.length > 0

  subject = "Запрос звонка от #{name}"
  text    = """
            Имя: #{name}\n
            Телефон: #{phone}\n
            E-mail: #{email}\n
            Вопрос: #{question}
            """

  data = _.extend {subject, text}, mailOptions

  # обрабатываем атачмент
  if qqfile?
    data.attachments = [{
      fileName: qqfile.name
      streamSource: fs.createReadStream(qqfile.path)
      contentType: qqfile.type
    }]

  # заставлять клиента ждать ответ мы не будем
  transport.sendMail data, (err, response)->
    if err?
      console.error err
      return res.json {success: false, err: "Непредвиденная ошибка сервера"}, 500

    res.json {success: true}