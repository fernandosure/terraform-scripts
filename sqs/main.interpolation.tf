# variable "queues" {
#   default = []
# }

# variable "environments" {
#   default = []
# }

# variable "buckets" {
#   default = []
# }

# resource "aws_sqs_queue" "death_letter_queue" {
#   count                     = "${length(var.queues) * length(var.environments)}"
#   name                      = "${var.queues[count.index / length(var.environments)]}-dqueue-${var.environments[count.index % length(var.environments)]}"
#   receive_wait_time_seconds = "${var.environments[count.index % length(var.environments)] == "prod" ? 10 : 20}"

#   tags {
#     Environment = "${var.environments[count.index % length(var.environments)]}"
#     appName     = "${var.queues[count.index / length(var.environments)]}"
#     type        = "deadletter"
#   }
# }

# data "template_file" "sqs_redrive_policy" {
#   count    = "${length(var.queues) * length(var.environments)}"
#   template = "{\"deadLetterTargetArn\":\"$${queue_arn}\",\"maxReceiveCount\":10}"

#   vars {
#     queue_arn = "${aws_sqs_queue.death_letter_queue.*.arn[count.index]}"
#   }
# }

# resource "aws_sqs_queue" "redrive_queue" {
#   count                     = "${length(var.queues) * length(var.environments)}"
#   name                      = "${var.queues[count.index / length(var.environments)]}-rqueue-${var.environments[count.index % length(var.environments)]}"
#   receive_wait_time_seconds = "${var.environments[count.index % length(var.environments)] == "prod" ? 10 : 20}"
#   redrive_policy            = "${data.template_file.sqs_redrive_policy.*.rendered[count.index]}"

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": "sqs:SendMessage",
#       "Resource": "arn:aws:sqs:*:*:${var.queues[count.index / length(var.environments)]}-rqueue-${var.environments[count.index % length(var.environments)]}"
#     }
#   ]
# }
# POLICY

# #
# # policy = <<POLICY
# # {
# # "Version": "2012-10-17",
# # "Statement": [
# #   {
# #     "Effect": "Allow",
# #     "Principal": "*",
# #     "Action": "sqs:SendMessage",
# #     "Resource": "arn:aws:sqs:*:*:${var.queues[count.index / length(var.environments)]}-rqueue-${var.environments[count.index % length(var.environments)]}",
# #     "Condition": {
# #       "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.*.arn[count.index]}" }
# #     }
# #   }
# # ]
# # }
# # POLICY
#   tags {
#     Environment = "${var.environments[count.index % length(var.environments)]}"
#     appName     = "${var.queues[count.index / length(var.environments)]}"
#     type        = "redrive"
#   }
# }

# resource "aws_s3_bucket" "bucket" {
#   count  = "${length(var.buckets) * length(var.environments)}"
#   bucket = "${var.buckets[count.index / length(var.environments)]}-${var.environments[count.index % length(var.environments)]}"
#   acl    = "private"

#   tags {
#     Environment = "${var.environments[count.index % length(var.environments)]}"
#     appName     = "${var.buckets[count.index / length(var.environments)]}"
#   }
# }

# resource "aws_s3_bucket_notification" "bucket_notification" {
#   count  = "${length(var.buckets) * length(var.environments)}"
#   bucket = "${aws_s3_bucket.bucket.*.id[count.index]}"

#   queue {
#     queue_arn     = "${aws_sqs_queue.redrive_queue.*.arn[count.index % length(var.environments)]}"
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".zip"
#   }

#   queue {
#     queue_arn     = "${aws_sqs_queue.redrive_queue.*.arn[count.index % length(var.environments)]}"
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".gzip"
#   }

#   queue {
#     queue_arn     = "${aws_sqs_queue.redrive_queue.*.arn[count.index % length(var.environments)]}"
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".rar"
#   }
# }

# output "redrive_queues" {
#   value = "${aws_sqs_queue.redrive_queue.*.arn}"
# }
# output "deadth_letter_queues" {
#   value = "${aws_sqs_queue.death_letter_queue.*.arn}"
# }

# output "s3_buckets" {
#   value = "${aws_s3_bucket.bucket.*.id}"
# }
