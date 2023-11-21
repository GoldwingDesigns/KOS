function first_test {
    parameter m, yourvar, myvar is "".
    return (m+yourvar+myvar).
}

function second_test {
    parameter m, yourvar is "hello", myvar is "".
    return (m+yourvar+myvar).
}

function third_test {
    parameter m, yourvar is "", myvar is "hello".
    return (m+yourvar+myvar).
}

function last_test {
    parameter m, yourvar is "", myvar is "".
    return (m+yourvar+myvar).
}
