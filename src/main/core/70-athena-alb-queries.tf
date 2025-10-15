resource "aws_athena_workgroup" "sh_queries" {
  name  = format("%s-queries-%s", local.project, var.env)
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = format("s3://%s", module.athena_query_results_bucket.s3_bucket_id)
    }
  }
}

resource "aws_athena_named_query" "alb_access_logs" {
  name      = "create-alb-access-logs-table"
  workgroup = aws_athena_workgroup.sh_queries.id
  database  = "default"

  query = <<-EOT
    CREATE EXTERNAL TABLE IF NOT EXISTS alb_access_logs (
            type string,
            time string,
            elb string,
            client_ip string,
            client_port int,
            target_ip string,
            target_port int,
            request_processing_time double,
            target_processing_time double,
            response_processing_time double,
            elb_status_code int,
            target_status_code string,
            received_bytes bigint,
            sent_bytes bigint,
            request_verb string,
            request_url string,
            request_proto string,
            user_agent string,
            ssl_cipher string,
            ssl_protocol string,
            target_group_arn string,
            trace_id string,
            domain_name string,
            chosen_cert_arn string,
            matched_rule_priority string,
            request_creation_time string,
            actions_executed string,
            redirect_url string,
            lambda_error_reason string,
            target_port_list string,
            target_status_code_list string,
            classification string,
            classification_reason string,
            conn_trace_id string
            )
            PARTITIONED BY
            (
             day STRING
            )
            ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
            WITH SERDEPROPERTIES (
            'serialization.format' = '1',
            'input.regex' = 
        '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\\s]+?)\" \"([^\\s]+)\" \"([^ ]*)\" \"([^ ]*)\" ?([^ ]*)?'
            )
            LOCATION 's3://${module.alb_logs_bucket.s3_bucket_id}/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${var.aws_region}/'
            TBLPROPERTIES
            (
             "projection.enabled" = "true",
             "projection.day.type" = "date",
             "projection.day.range" = "2022/01/01,NOW",
             "projection.day.format" = "yyyy/MM/dd",
             "projection.day.interval" = "1",
             "projection.day.interval.unit" = "DAYS",
             "storage.location.template" = "s3://${module.alb_logs_bucket.s3_bucket_id}/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${var.aws_region}/$${day}"
            )
  EOT
}

resource "aws_athena_named_query" "alb_logs_5xx" {
  name      = "alb-logs-5xx"
  workgroup = aws_athena_workgroup.sh_queries.id
  database  = "default"

  query = <<-EOT
    SELECT * FROM alb_access_logs
    WHERE elb = '${aws_lb.sh_api.arn_suffix}'
    AND elb_status_code >= 500
    --AND day = '2024/09/18' -- strongly suggested for indexing, format: yyyy/mm/dd
    --AND parse_datetime(time,'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z') -- UTC time
    --     BETWEEN parse_datetime('2024-09-18-08:00:00','yyyy-MM-dd-HH:mm:ss') 
    --     AND parse_datetime('2024-09-18-09:00:00','yyyy-MM-dd-HH:mm:ss') 

  EOT
}
