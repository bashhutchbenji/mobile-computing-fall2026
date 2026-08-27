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