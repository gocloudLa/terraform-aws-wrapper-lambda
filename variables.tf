/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

/*----------------------------------------------------------------------*/
/* ALB | Variable Definition                                            */
/*----------------------------------------------------------------------*/

variable "lambda_parameters" {
  type        = any
  description = ""
  default     = {}
}

variable "lambda_defaults" {
  description = "Map of default values which will be used for each item."
  type        = any
  default     = {}
}
