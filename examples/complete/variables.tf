/*----------------------------------------------------------------------*/
/* RDS | Variable Definition                                            */
/*----------------------------------------------------------------------*/

variable "lambda_defaults" {
  description = "Map of default values which will be used for each lambda function."
  type        = any
  default     = {}
}

variable "lambda_parameters" {
  description = "Maps of lambda functions to create a wrapper from. Values are passed through to the module."
  type        = any
  default     = {}
}