os.execute("stty -echoctl")
local inline = require("inline")

-- Секция 1: Математические функции
inline[[
#include <math.h>

double calculate_hypotenuse(double a, double b) {
    return sqrt(a*a + b*b);
}

int factorial(int n) {
    return (n <= 1) ? 1 : n * factorial(n - 1);
}
]]

-- Секция 2: Системные функции
inline[[
#include <unistd.h>
#include <sys/types.h>

int get_process_id() {
    return getpid();
}

void sleep_seconds(int seconds) {
    sleep(seconds);
}
]]

-- Тестирование всех функций

-- Математика
print("Hypotenuse of 3 and 4:", calculate_hypotenuse(3, 4)) --> 5.0
print("Factorial of 5:", factorial(5)) --> 120

-- Системные функции
print("Process ID:", get_process_id())
print("Sleeping for 1 second...")
sleep_seconds(1)