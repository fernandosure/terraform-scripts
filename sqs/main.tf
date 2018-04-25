variable "queues"          { default = [] }
variable "environments"    { default = [] }


resource "aws_sqs_queue" "death_letter_queue" {
  count                     = "${length(var.queues) * length(var.environments)}"
  name                      = "${var.queues[count.index / length(var.environments)]}-dqueue-${var.environments[count.index % length(var.environments)]}"
  receive_wait_time_seconds = "${var.environments[count.index % length(var.environments)] == "prod" ? 10 : 20}"

  tags {
    Environment = "${var.environments[count.index % length(var.environments)]}"
    appName = "${var.queues[count.index / length(var.environments)]}"
    type ="deadletter"
  }
}

data "template_file" "sqs_redrive_policy" {
  count = "${length(var.queues) * length(var.environments)}"
  template = "{\"deadLetterTargetArn\":\"$${queue_arn}\",\"maxReceiveCount\":10}"
  vars {
    queue_arn = "${aws_sqs_queue.death_letter_queue.*.arn[count.index]}"
  }
}

resource "aws_sqs_queue" "redrive_queue" {
  count                     = "${length(var.queues) * length(var.environments)}"
  name                      = "${var.queues[count.index / length(var.environments)]}-rqueue-${var.environments[count.index % length(var.environments)]}"
  receive_wait_time_seconds = "${var.environments[count.index % length(var.environments)] == "prod" ? 10 : 20}"
  redrive_policy            = "${data.template_file.sqs_redrive_policy.*.rendered[count.index]}"

  tags {
    Environment = "${var.environments[count.index % length(var.environments)]}"
    appName = "${var.queues[count.index / length(var.environments)]}"
    type ="redrive"
  }
}
