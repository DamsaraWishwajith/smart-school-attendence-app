class Attendance {
  final String id;
  final String studentName;
  final String studentId;
  final DateTime dateTime;
  final String status; // Present, Late, Absent
  final String subject;
  final String location;

  Attendance({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.dateTime,
    required this.status,
    required this.subject,
    required this.location,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentName: json['student_name'],
      studentId: json['student_id'],
      dateTime: DateTime.parse(json['date_time']),
      status: json['status'],
      subject: json['subject'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'student_id': studentId,
      'date_time': dateTime.toIso8601String(),
      'status': status,
      'subject': subject,
      'location': location,
    };
  }
}
