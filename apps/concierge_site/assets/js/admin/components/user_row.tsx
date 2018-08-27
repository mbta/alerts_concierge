import * as React from "react";
import User from "../interfaces/user";
import { format as formatPhoneNumber } from "../formatters/phone_number";

interface UserRowProps {
  user: User;
  deleteUser: (user: User) => any;
};

export const UserRow = (props: UserRowProps) => (
  <tr>
    <td>{props.user.email}</td>
    <td>{formatPhoneNumber(props.user.phoneNumber)}</td>
    <td>
      <button type="button" className="btn btn-link" onClick={() => props.deleteUser(props.user)}>
        Delete
      </button>
    </td>
  </tr>
);
