fn main() {
    // Прошло 10^16 наносекунд.
    // Это приблизительно 115.7 суток.
    let elapsed: f64 = 10000000000000000.0;

    // Хотим прибавить ровно одну наносекунду.
    let next = elapsed + 1.0;

    // Проверяем, продвинулось ли время.
    let difference = next - elapsed;

    print("Elapsed: ", elapsed, " ns");
    print("Next: ", next, " ns");
    print("Delta: ", difference, " ns");

    if next == elapsed {
        print("FATAL: CLOCK DID NOT ADVANCE!");
    }
}