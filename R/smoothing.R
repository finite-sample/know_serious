smooth_stata_lowess <- function(x, y, bandwidth = 0.8) {
  stopifnot(
    length(x) == length(y), length(bandwidth) == 1L,
    is.finite(bandwidth), bandwidth > 0, bandwidth <= 1
  )
  observed <- is.finite(x) & is.finite(y)
  x <- x[observed]
  y <- y[observed]
  if (!length(x)) stop("No finite observations to smooth")
  ordering <- order(x, seq_along(x))
  x <- x[ordering]
  y <- y[ordering]
  observations <- length(x)
  half_window <- max(0L, floor((observations * bandwidth - 0.5) / 2))
  fitted <- vapply(seq_len(observations), function(index) {
    window <- seq.int(max(1L, index - half_window), min(observations, index + half_window))
    centered_x <- x[window] - x[index]
    radius <- 1.0001 * max(abs(centered_x))
    weights <- if (radius == 0) rep(1, length(window)) else (1 - (abs(centered_x) / radius)^3)^3
    total_weight <- sum(weights)
    mean_x <- sum(weights * centered_x) / total_weight
    mean_y <- sum(weights * y[window]) / total_weight
    variance_x <- sum(weights * (centered_x - mean_x)^2)
    if (variance_x <= .Machine$double.eps * total_weight) {
      return(mean_y)
    }
    slope <- sum(weights * (centered_x - mean_x) * (y[window] - mean_y)) / variance_x
    mean_y - slope * mean_x
  }, numeric(1))
  list(x = x, y = fitted)
}
