def send_mail(to, from, subject, body)
  Mail.deliver do
    from from
    to to
    subject subject
    body body
  end
end