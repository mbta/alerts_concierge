[
  # in AlertProcessor.Helpers.EnvHelper
  ~r/Function Mix\.env\/0 does not exist/,
  # ignore warnings caused by :ex_aws_sns being excluded from the PLT
  ~r/Function ExAws\.SNS\..+ does not exist/
]
