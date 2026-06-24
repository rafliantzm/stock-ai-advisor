export type ApiErrorCode =
  | "unauthorized"
  | "validation_error"
  | "not_found"
  | "database_error"
  | "method_not_allowed";

export class ApiError extends Error {
  code: ApiErrorCode;
  status: number;
  details?: unknown;

  constructor(code: ApiErrorCode, message: string, status: number, details?: unknown) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

export function unauthorized(message = "Unauthorized") {
  return new ApiError("unauthorized", message, 401);
}

export function validationError(message: string, details?: unknown) {
  return new ApiError("validation_error", message, 400, details);
}

export function notFound(message: string, details?: unknown) {
  return new ApiError("not_found", message, 404, details);
}

export function databaseError(message: string, details?: unknown) {
  return new ApiError("database_error", message, 500, details);
}

export function methodNotAllowed(message = "Method not allowed") {
  return new ApiError("method_not_allowed", message, 405);
}
