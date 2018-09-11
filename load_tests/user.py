from random import randrange


class User():
    """Helpers functions for defining user properties"""

    @staticmethod
    def random_email():
        return "user" + "".join([str(randrange(10)) for x in range(6)]) + "@example.com"

    @staticmethod
    def random_password():
        return "test" + "".join([str(randrange(10)) for x in range(10)])
