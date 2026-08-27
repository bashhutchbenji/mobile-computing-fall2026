class Student {
  String? name;
  int? id;
  List<double>? grades;

  Student(this.name, this.id, this.grades);

  double calculateGPA(List<double> grades) {
    double sum = 0;
    for (int i = 0; i < grades.length; i++) {
      sum += grades[i];
    }
    return sum / grades.length;
  }
}

void main() {
  var students = [
    Student('Sahar', 1, [3.8, 4.0, 3.6]),
    Student('Alex', 2, [3.2, 3.5, 3.9]),
  ];

  for (var s in students) {
    print('${s.name}: ${s.calculateGPA(s.grades!)}');
  }
}